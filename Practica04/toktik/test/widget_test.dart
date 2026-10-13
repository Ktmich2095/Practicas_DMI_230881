import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktik_app/domain/entities/video_post.dart';
import 'package:toktik_app/domain/repositories/favorites_repository.dart';
import 'package:toktik_app/domain/repositories/video_catalog_repository.dart';
import 'package:toktik_app/domain/entities/video_batch.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/repositories/preferences_repository.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/main.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';

const video = VideoPost(caption: 'Test', videoUrl: 'test.mp4', likes: 10);

class MemoryFavorites extends FavoritesRepository {
  Set<String> ids = {};
  bool fail = false;
  @override
  Future<Set<String>> read() async => Set.of(ids);
  @override
  Future<void> save(Set<String> values) async {
    if (fail) throw StateError('storage unavailable');
    ids = Set.of(values);
  }
}

class MemorySettings implements PreferencesRepository {
  @override
  Future<AppPreferences> read() async => const AppPreferences();
  @override
  Future<void> save(AppPreferences preferences) async {}
}

class TestVideos implements VideoCatalogRepository {
  @override
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0}) async =>
      const VideoBatch(videos: [video], source: VideoSource.local);
}

void main() {
  late MemoryFavorites storage;
  late DiscoverProvider provider;
  setUp(() {
    storage = MemoryFavorites();
    provider = DiscoverProvider(
      repository: TestVideos(),
      favoritesRepository: storage,
    );
  });
  tearDown(() => provider.dispose());
  test('Favorite toggles once, persists, and restores on reload', () async {
    await provider.loadNextPage();
    await provider.toggleFavorite(video);
    expect(provider.likes(video), 11);
    expect(provider.favorites, [video]);
    final restored = DiscoverProvider(
      repository: TestVideos(),
      favoritesRepository: storage,
    );
    await restored.loadNextPage();
    expect(restored.isFavorite(video), isTrue);
    restored.dispose();
    await provider.toggleFavorite(video);
    expect(provider.likes(video), 10);
    expect(storage.ids, isEmpty);
    expect(provider.favorites, isEmpty);
  });
  test('Storage failure rolls back favorite and count', () async {
    await provider.loadNextPage();
    storage.fail = true;
    await provider.toggleFavorite(video);
    expect(provider.isFavorite(video), isFalse);
    expect(provider.likes(video), 10);
    expect(provider.persistenceError, isNotNull);
  });
  testWidgets('Favorites empty state and all navigation destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(MemorySettings()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    await tester.tap(find.text('Favorites'));
    await tester.pump();
    // Complete loading with an empty favorites list; no native player is needed.
    await provider.loadNextPage();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border), findsWidgets);
    expect(
      find.text('Explora videos y guarda los que más te gusten.'),
      findsOneWidget,
    );
  });
}
