import 'package:flutter_test/flutter_test.dart';
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/domain/repositories/theme_audio_repository.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/infrastructure/repositories/preferences_favorites_repository.dart';
import 'package:toktik_app/infrastructure/repositories/audioplayers_intro_repository.dart';
import 'package:toktik_app/infrastructure/repositories/audioplayers_theme_repository.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/theme_audio_provider.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';

import 'support/memory_store.dart';
import 'sources_test.dart' show localVideo;
import 'widget_test.dart' show TestVideos;

class FakeAudio implements ThemeAudioRepository {
  final List<String> events = [];
  bool failStop = false;
  @override
  Future<void> play(String asset) async {
    events.add('play:$asset');
  }

  @override
  Future<void> stop() async {
    if (failStop) throw StateError('stop failed');
    events.add('stop');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Unused audio repositories do not initialize native audio on stop or dispose', () async {
    final intro = AudioplayersIntroRepository();
    final theme = AudioplayersThemeRepository();
    await intro.stop();
    await theme.stop();
    await intro.dispose();
    await theme.dispose();
  });
  test('Date ranges and manual season persist across restart', () async {
    expect(Season.forDate(DateTime(2026, 10, 1)), Season.halloween);
    expect(Season.forDate(DateTime(2026, 12, 31)), Season.christmas);
    expect(Season.forDate(DateTime(2026, 2, 14)), Season.valentine);
    expect(Season.forDate(DateTime(2026, 2, 15)), Season.normal);
    final store = MemoryStore();
    final repository = SharedPreferencesRepository(storage: store);
    var now = DateTime(2026, 10, 13);
    final settings = SettingsProvider(repository, clock: () => now);
    await settings.initialize(observeDate: false);
    expect(settings.season, Season.halloween);
    await settings.selectSeason(Season.christmas);
    await settings.selectSource(VideoSource.pixabay);
    await settings.setMuted(false);
    await settings.setThemeAudio(true);
    final reloaded = SettingsProvider(repository, clock: () => now);
    await reloaded.initialize(observeDate: false);
    expect(reloaded.season, Season.christmas);
    expect(reloaded.preferences.source, VideoSource.pixabay);
    expect(reloaded.preferences.muted, isFalse);
    expect(reloaded.preferences.themeAudio, isTrue);
    await reloaded.selectSeason(null);
    now = DateTime(2026, 2, 14);
    reloaded.refreshDate();
    expect(reloaded.season, Season.valentine);
    await reloaded.selectSource(VideoSource.random);
    expect((await repository.read()).source, VideoSource.random);
    settings.dispose();
    reloaded.dispose();
  });
  test('Preference write failure keeps last durable setting', () async {
    final store = MemoryStore();
    final settings = SettingsProvider(
      SharedPreferencesRepository(storage: store),
    );
    store.fail = true;
    expect(await settings.selectSource(VideoSource.coverr), isFalse);
    expect(settings.preferences.source, VideoSource.random);
    expect(settings.error, isNotNull);
    settings.dispose();
  });
  test(
    'Favorite snapshots survive a different source and empty legacy migration',
    () async {
      final store = MemoryStore();
      final repo = PreferencesFavoritesRepository(storage: store);
      await repo.saveVideos([localVideo]);
      final feed = DiscoverProvider(
        repository: TestVideos(),
        favoritesRepository: repo,
      );
      await feed.changeSource(VideoSource.archive);
      expect(feed.favorites.single.id, localVideo.id);
      await feed.toggleFavorite(localVideo);
      expect(await repo.read(), isEmpty);
      store.values['toktik.favorites.v1'] = ['old-url'];
      expect(await repo.read(), isEmpty);
      feed.dispose();
    },
  );
  test(
    'Legacy ambient preference never plays on silence, pause or resume',
    () async {
      final repository = SharedPreferencesRepository(storage: MemoryStore());
      await repository.save(
        const AppPreferences(manualSeason: Season.christmas, themeAudio: true),
      );
      final settings = SettingsProvider(repository);
      await settings.initialize(observeDate: false);
      final backend = FakeAudio();
      final audio = ThemeAudioProvider(backend, settings);
      await audio.synchronize();
      expect(audio.playing, isFalse);
      await audio.setVideoAudible(true);
      expect(audio.playing, isFalse);
      expect(backend.events.last, 'stop');
      await audio.setVideoAudible(false);
      expect(audio.playing, isFalse);
      await audio.setForeground(false);
      expect(audio.playing, isFalse);
      await audio.setForeground(true);
      expect(audio.playing, isFalse);
      audio.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(backend.events.last, 'dispose');
      settings.dispose();
    },
  );
  test('Failed audio stop blocks permission for audible video', () async {
    final repository = SharedPreferencesRepository(storage: MemoryStore());
    await repository.save(
      const AppPreferences(manualSeason: Season.halloween, themeAudio: true),
    );
    final settings = SettingsProvider(repository);
    await settings.initialize(observeDate: false);
    final backend = FakeAudio();
    final audio = ThemeAudioProvider(backend, settings);
    await audio.synchronize();
    backend.failStop = true;
    await expectLater(audio.setVideoAudible(true), throwsStateError);
    backend.failStop = false;
    audio.dispose();
    await Future<void>.delayed(Duration.zero);
    settings.dispose();
  });
}
