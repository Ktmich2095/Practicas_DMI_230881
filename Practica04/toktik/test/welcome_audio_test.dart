import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktik_app/config/branding/brand_assets.dart';
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/infrastructure/repositories/audioplayers_intro_repository.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/presentation/providers/intro_audio_provider.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/theme_audio_provider.dart';

import 'identity_test.dart' show FakeIntroAudio;
import 'preferences_themes_test.dart' show FakeAudio;
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Absent MP3 skips native player and completes without errors', () async {
    final repository = AudioplayersIntroRepository();
    await repository.playOnce('sounds/not-provided.mp3');
    await repository.stop();
    await repository.dispose();
  });

  for (final season in Season.values) {
    test(
      '${season.name} welcome plays once despite muted videos and resume',
      () async {
        final preferences = SharedPreferencesRepository(storage: MemoryStore());
        final settings = SettingsProvider(preferences);
        await settings.initialize(observeDate: false);
        expect(settings.preferences.introSound, isTrue);
        expect(settings.preferences.muted, isTrue);
        final theme = ThemeAudioProvider(FakeAudio(), settings);
        final sound = FakeIntroAudio();
        final intro = IntroAudioProvider(sound, theme, settings);
        await intro.startWelcome(season);
        expect(sound.events, ['play:sounds/${season.name}.mp3']);
        expect(BrandAssets.introAudio(season), 'sounds/${season.name}.mp3');
        intro.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future<void>.delayed(Duration.zero);
        expect(sound.events.last, 'stop');
        intro.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await intro.startWelcome(season);
        await intro.stop();
        await intro.startWelcome(season);
        expect(sound.events.where((e) => e.startsWith('play:')).length, 1);
        intro.dispose();
        await Future<void>.delayed(Duration.zero);
        theme.dispose();
        settings.dispose();
      },
    );
  }

  test(
    'Explicit welcome opt-out persists independently of video mute',
    () async {
      final preferences = SharedPreferencesRepository(storage: MemoryStore());
      await preferences.save(
        const AppPreferences(introSound: false, muted: false),
      );
      final settings = SettingsProvider(preferences);
      await settings.initialize(observeDate: false);
      final theme = ThemeAudioProvider(FakeAudio(), settings);
      final sound = FakeIntroAudio();
      final intro = IntroAudioProvider(sound, theme, settings);
      await intro.startWelcome(Season.normal);
      expect(sound.events, isEmpty);
      intro.dispose();
      await Future<void>.delayed(Duration.zero);
      theme.dispose();
      settings.dispose();
    },
  );
}
