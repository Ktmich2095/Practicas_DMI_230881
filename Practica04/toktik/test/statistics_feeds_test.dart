import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktik_app/config/helpers/human_formats.dart';
import 'package:toktik_app/domain/entities/video_post.dart';
import 'package:toktik_app/domain/entities/video_statistics.dart';
import 'package:toktik_app/domain/entities/video_batch.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/domain/repositories/video_catalog_repository.dart';
import 'package:toktik_app/infrastructure/repositories/preferences_favorites_repository.dart';
import 'package:toktik_app/infrastructure/repositories/preferences_statistics_repository.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/main.dart';

import 'support/memory_store.dart';
import 'playback_coordinator_test.dart' show FakePlayer;
import 'widget_test.dart' show MemorySettings;

class Catalog implements VideoCatalogRepository {
  int requests = 0;
  List<VideoPost> items = const [
    VideoPost(caption: 'Uno', videoUrl: 'one.mp4'),
    VideoPost(caption: 'Dos', videoUrl: 'two.mp4'),
    VideoPost(caption: 'Tres', videoUrl: 'three.mp4'),
  ];
  @override
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0}) async {
    requests++;
    return VideoBatch(videos: items, source: VideoSource.local);
  }
}

class BrokenPlayer extends FakePlayer {
  BrokenPlayer(super.dataSource);
  @override
  Future<void> initialize() async => throw StateError('network unavailable');
}

class RepeatedCatalog extends Catalog {
  @override
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0}) async {
    requests++;
    return VideoBatch(videos: items, source: VideoSource.local, hasMore: true);
  }
}

class FailedReadStore extends MemoryStore {
  bool failReads = false;
  @override
  Future<String?> getString(String key) {
    if (failReads) throw StateError('storage read unavailable');
    return super.getString(key);
  }
}

void main() {
  testWidgets('Landscape keeps favorite and sound controls tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feed = DiscoverProvider(
      repository: Catalog(),
      favoritesRepository: PreferencesFavoritesRepository(
        storage: MemoryStore(),
      ),
    );
    await feed.loadNextPage();
    final playback = PlaybackCoordinator(
      createController: (v) => FakePlayer(v.videoUrl),
    );
    final settings = SettingsProvider(MemorySettings());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: feed),
          ChangeNotifierProvider.value(value: playback),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Guardar en favoritos').hitTestable(),
      findsOneWidget,
    );
    expect(find.byTooltip('Activar sonido').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Guardar en favoritos'));
    await tester.pumpAndSettle();
    expect(feed.isFavorite(feed.videos.first), isTrue);
    await tester.tap(find.byTooltip('Activar sonido'));
    await tester.pumpAndSettle();
    expect(playback.muted, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    playback.dispose();
    feed.dispose();
    settings.dispose();
    await tester.pump();
  });
  testWidgets(
    'Favorites distinguishes a failed restore from an empty collection and retries',
    (tester) async {
      final store = FailedReadStore()..failReads = true;
      final catalog = Catalog()..items = [];
      final feed = DiscoverProvider(
        repository: catalog,
        favoritesRepository: PreferencesFavoritesRepository(storage: store),
      );
      final settings = SettingsProvider(MemorySettings());
      await feed.loadNextPage();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: feed),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MyApp(),
        ),
      );
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos recuperar tus favoritos.'), findsOneWidget);
      expect(find.text('Aún no tienes favoritos.'), findsNothing);
      store.failReads = false;
      await tester.tap(find.text('Reintentar lectura'));
      await tester.pumpAndSettle();
      expect(feed.favoritesReady, isTrue);
      expect(feed.persistenceError, isNull);
      expect(find.text('Aún no tienes favoritos.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      feed.dispose();
      settings.dispose();
    },
  );
  test('Failed restoration cannot overwrite stored favorites or view counters; retry recovers', () async {
    final store = FailedReadStore();
    final favorites = PreferencesFavoritesRepository(storage: store);
    final statistics = PreferencesStatisticsRepository(storage: store);
    final catalog = Catalog();
    final original = catalog.items.first, second = catalog.items[1];
    await favorites.saveVideos([original]);
    await statistics.saveViewIncrements({VideoStatistics.key(original): 7});
    final snapshot = Map<String, Object>.of(store.values);
    store.failReads = true;
    final feed = DiscoverProvider(
      repository: catalog,
      favoritesRepository: favorites,
      statisticsRepository: statistics,
    );
    await feed.loadNextPage();
    await feed.toggleFavorite(second);
    await expectLater(feed.recordView(second), throwsStateError);
    expect(store.values, snapshot);
    expect(feed.isFavorite(second), isFalse);
    expect(feed.persistenceError, isNotNull);
    store.failReads = false;
    await feed.toggleFavorite(second);
    expect(feed.isFavorite(original), isTrue);
    expect(feed.isFavorite(second), isTrue);
    await feed.recordView(second);
    final increments = await statistics.readViewIncrements();
    expect(increments[VideoStatistics.key(original)], 7);
    expect(increments[VideoStatistics.key(second)], 1);
    feed.dispose();
  });
  test(
    'Repeated pages stop pagination without losing the current catalog',
    () async {
      final catalog = RepeatedCatalog();
      final feed = DiscoverProvider(
        repository: catalog,
        favoritesRepository: PreferencesFavoritesRepository(
          storage: MemoryStore(),
        ),
      );
      await feed.loadNextPage();
      await feed.loadMore();
      expect(feed.videos.length, 3);
      expect(feed.hasMore, isFalse);
      await feed.loadMore();
      expect(catalog.requests, 2);
      feed.dispose();
    },
  );

  test(
    'Views exceed likes even when the source has only one extra view',
    () async {
      final catalog = Catalog();
      catalog.items = [
        const VideoPost(
          caption: '',
          videoUrl: 'one.mp4',
          likes: 100,
          views: 101,
        ),
      ];
      final feed = DiscoverProvider(
        repository: catalog,
        favoritesRepository: PreferencesFavoritesRepository(
          storage: MemoryStore(),
        ),
      );
      await feed.loadNextPage();
      final video = feed.videos.single;
      final views = feed.views(video);
      await feed.toggleFavorite(video);
      expect(feed.likes(video), 101);
      expect(feed.views(video), views);
      expect(feed.views(video), greaterThan(feed.likes(video)));
      await feed.toggleFavorite(video);
      expect(feed.likes(video), 100);
      feed.dispose();
    },
  );
  test(
    'Damaged view storage does not prevent restoring favorite snapshots',
    () async {
      final store = MemoryStore();
      final favorites = PreferencesFavoritesRepository(storage: store);
      await favorites.saveVideos([Catalog().items.first]);
      store.values[PreferencesStatisticsRepository.key] = 'invalid JSON';
      final feed = DiscoverProvider(
        repository: Catalog(),
        favoritesRepository: favorites,
        statisticsRepository: PreferencesStatisticsRepository(storage: store),
      );
      await feed.loadNextPage();
      expect(feed.favorites.single.id, Catalog().items.first.id);
      expect(feed.persistenceError, isNotNull);
      feed.dispose();
    },
  );

  testWidgets('Failed playback shows a recoverable error in every feed', (
    tester,
  ) async {
    final feed = DiscoverProvider(
      repository: Catalog(),
      favoritesRepository: PreferencesFavoritesRepository(
        storage: MemoryStore(),
      ),
    );
    await feed.loadNextPage();
    await feed.toggleFavorite(feed.videos.first);
    var created = 0;
    final playback = PlaybackCoordinator(
      createController: (v) {
        created++;
        return BrokenPlayer(v.id);
      },
    );
    final settings = SettingsProvider(MemorySettings());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: feed),
          ChangeNotifierProvider.value(value: playback),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final tab in ['For You', 'Discover', 'Favorites']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo reproducir este video'), findsOneWidget);
      expect(
        playback.controllers.values.any((p) => p.value.isPlaying),
        isFalse,
      );
    }
    final before = created;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(created, greaterThan(before));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    playback.dispose();
    feed.dispose();
    settings.dispose();
    await tester.pump();
  });

  test(
    'Stable demo metrics, composed identity and requested counter formats',
    () {
      final videos = Catalog().items;
      final stats = videos.map(VideoStatistics.resolve).toList();
      expect(stats.map((v) => v.likes).toSet().length, videos.length);
      for (var i = 0; i < videos.length; i++) {
        expect(stats[i].likes, greaterThan(0));
        expect(stats[i].views, greaterThan(stats[i].likes));
        expect(VideoStatistics.resolve(videos[i]).likes, stats[i].likes);
      }
      const a = VideoPost(
        caption: '',
        videoUrl: 'x',
        providerId: '42',
        origin: VideoSource.coverr,
      );
      const b = VideoPost(
        caption: '',
        videoUrl: 'x',
        providerId: '42',
        origin: VideoSource.pixabay,
      );
      expect(a.id, isNot(b.id));
      expect(VideoStatistics.key(a), isNot(VideoStatistics.key(b)));
      const real = VideoPost(
        caption: '',
        videoUrl: 'real',
        likes: 1250,
        views: 15800,
      );
      expect(VideoStatistics.resolve(real).likes, 1250);
      expect(VideoStatistics.resolve(real).views, 15800);
      for (final entry in {
        850: '850',
        1250: '1.2K',
        12500: '12.5K',
        125000: '125K',
        1250000: '1.2M',
        15800000: '15.8M',
      }.entries) {
        expect(
          HumanFormats.humanReadableNumber(entry.key.toDouble()),
          entry.value,
        );
      }
    },
  );

  test('Global likes, snapshots and deduplicated views survive restart and absent catalog', () async {
    final store = MemoryStore();
    final catalog = Catalog();
    DiscoverProvider create() => DiscoverProvider(
      repository: catalog,
      favoritesRepository: PreferencesFavoritesRepository(storage: store),
      statisticsRepository: PreferencesStatisticsRepository(storage: store),
    );
    final feed = create();
    await feed.loadNextPage();
    final video = feed.videos.first;
    final likes = feed.likes(video), views = feed.views(video);
    await feed.toggleFavorite(video);
    expect(feed.likes(feed.favorites.single), likes + 1);
    expect(
      feed.likes(feed.discoverVideos.firstWhere((v) => v.id == video.id)),
      likes + 1,
    );
    await feed.recordView(video);
    await feed.recordView(video);
    expect(feed.views(video), views + 1);
    catalog.items = [];
    final restored = create();
    await restored.loadNextPage();
    expect(restored.favorites.single.id, video.id);
    expect(restored.views(restored.favorites.single), views + 1);
    await restored.toggleFavorite(restored.favorites.single);
    expect(restored.likes(video), likes);
    expect(restored.favorites, isEmpty);
    feed.dispose();
    restored.dispose();
  });

  test('Only actual active playback progress qualifies; no rebuild, buffering or revisit count', () async {
    var counted = 0;
    final playback = PlaybackCoordinator(
      createController: (v) => FakePlayer(v.id),
      onQualifiedView: (_) async {
        counted++;
      },
    );
    final videos = Catalog().items;
    await playback.select(videos, 0);
    final player = playback.current!;
    for (var i = 1; i <= 6; i++) {
      player.value = player.value.copyWith(
        position: Duration(milliseconds: i * 500),
      );
    }
    expect(counted, 1);
    await playback.select(videos, 1);
    await playback.select(videos, 0);
    for (var i = 7; i <= 16; i++) {
      player.value = player.value.copyWith(
        position: Duration(milliseconds: i * 500),
      );
    }
    expect(counted, 1);
    final second = playback.controllers[videos[1].id]!;
    for (var i = 1; i <= 8; i++) {
      second.value = second.value.copyWith(
        position: Duration(milliseconds: i * 500),
      );
    }
    expect(counted, 1);
    await playback.select(videos, 1);
    second.value = second.value.copyWith(isBuffering: true);
    for (var i = 9; i <= 16; i++) {
      second.value = second.value.copyWith(
        position: Duration(milliseconds: i * 500),
      );
    }
    expect(counted, 1);
    playback.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  testWidgets(
    'All three tabs play, share favorites, retain position and do not refetch',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalog = Catalog(), store = MemoryStore();
      final feed = DiscoverProvider(
        repository: catalog,
        favoritesRepository: PreferencesFavoritesRepository(storage: store),
      );
      await feed.loadNextPage();
      final playback = PlaybackCoordinator(
        createController: (v) => FakePlayer(v.id),
      );
      final settings = SettingsProvider(MemorySettings());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: feed),
            ChangeNotifierProvider.value(value: playback),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(playback.current!.value.isPlaying, isTrue);
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final forYou = playback.current!.dataSource;
      final saved = feed.videos.firstWhere((v) => v.id == forYou);
      await feed.toggleFavorite(saved);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(playback.current!.value.isPlaying, isTrue);
      expect(
        playback.controllers.values.where((p) => p.value.isPlaying).length,
        1,
      );
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(playback.current!.dataSource, saved.id);
      expect(playback.current!.value.isPlaying, isTrue);
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();
      expect(playback.current!.dataSource, forYou);
      expect(catalog.requests, 1);
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      final removed = playback.current!;
      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();
      expect(removed.value.isPlaying, isFalse);
      expect(find.text('Aún no tienes favoritos.'), findsOneWidget);
      await tester.tap(find.text('Ir a For You'));
      await tester.pumpAndSettle();
      expect(playback.current!.value.isPlaying, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      playback.dispose();
      feed.dispose();
      settings.dispose();
      await tester.pump();
    },
  );
}
