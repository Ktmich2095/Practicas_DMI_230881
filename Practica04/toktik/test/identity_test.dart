import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktik_app/config/branding/brand_assets.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/domain/entities/season_calendar.dart';
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/repositories/launcher_icon_repository.dart';
import 'package:toktik_app/domain/repositories/intro_audio_repository.dart';
import 'package:toktik_app/infrastructure/repositories/android_launcher_icon_repository.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/presentation/providers/season_identity_provider.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/intro_audio_provider.dart';
import 'package:toktik_app/presentation/providers/theme_audio_provider.dart';
import 'package:toktik_app/presentation/widgets/branding/season_intro.dart';
import 'package:toktik_app/presentation/widgets/branding/toktik_logo.dart';

import 'support/memory_store.dart';
import 'preferences_themes_test.dart' show FakeAudio;
import 'playback_coordinator_test.dart' show FakePlayer;

import 'package:toktik_app/presentation/providers/playback_coordinator.dart';
import 'package:toktik_app/domain/entities/video_post.dart';

class FakeIcons implements LauncherIconRepository {
  final List<Season> calls = [];
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<void> apply(Season season) async {
    if (fail) throw StateError('launcher unavailable');
    calls.add(season);
  }
}

class FakeIntroAudio implements IntroAudioRepository {
  final List<String> events = [];
  @override
  Future<void> playOnce(String asset) async {
    events.add('play:$asset');
  }

  @override
  Future<void> stop() async {
    events.add('stop');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Calendar includes endpoints and supports configurable cross-year intervals', () {
    expect(Season.forDate(DateTime(2026, 9, 30)), Season.normal);
    expect(Season.forDate(DateTime(2026, 10, 31)), Season.halloween);
    expect(Season.forDate(DateTime(2026, 11, 1)), Season.normal);
    expect(Season.forDate(DateTime(2026, 12, 1)), Season.christmas);
    expect(Season.forDate(DateTime(2026, 2, 1)), Season.valentine);
    const range = SeasonRange('custom', 12, 15, 1, 10);
    expect(range.contains(DateTime(2027, 1, 5)), isTrue);
    expect(range.contains(DateTime(2027, 6, 1)), isFalse);
  });
  test('Native identity follows restored/manual/automatic season without duplicate writes', () async {
    final store = MemoryStore();
    final repo = SharedPreferencesRepository(storage: store);
    await repo.save(const AppPreferences(manualSeason: Season.christmas));
    final settings = SettingsProvider(
      repo,
      clock: () => DateTime(2026, 10, 13),
    );
    final icons = FakeIcons();
    final identity = SeasonIdentityProvider(settings, icons);
    await settings.initialize(observeDate: false);
    await identity.synchronize();
    expect(icons.calls, [Season.christmas]);
    await settings.selectSeason(Season.valentine);
    await identity.synchronize();
    expect(icons.calls.last, Season.valentine);
    await settings.selectSeason(null);
    await identity.synchronize();
    expect(icons.calls.last, Season.halloween);
    final count = icons.calls.length;
    await identity.synchronize();
    expect(icons.calls.length, count);
    identity.dispose();
    settings.dispose();
  });
  test('Icon update errors are recoverable', () async {
    final settings = SettingsProvider(
      SharedPreferencesRepository(storage: MemoryStore()),
    );
    await settings.initialize(observeDate: false);
    final icons = FakeIcons()..fail = true;
    final identity = SeasonIdentityProvider(settings, icons);
    await identity.synchronize();
    expect(identity.error, isNotNull);
    icons.fail = false;
    await identity.synchronize();
    expect(identity.error, isNull);
    identity.dispose();
    settings.dispose();
  });
  test('Android MethodChannel sends only the season identifier', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidLauncherIconRepository.channel, (
          call,
        ) async {
          received = call;
          return null;
        });
    await AndroidLauncherIconRepository().apply(Season.halloween);
    expect(received?.method, 'setSeason');
    expect(received?.arguments, {'season': 'halloween'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidLauncherIconRepository.channel, null);
  });
  test(
    'Welcome is one-shot, independent of video mute, with no ambient audio',
    () async {
      final repo = SharedPreferencesRepository(storage: MemoryStore());
      await repo.save(
        const AppPreferences(
          manualSeason: Season.christmas,
          themeAudio: true,
          introSound: true,
          muted: false,
        ),
      );
      final settings = SettingsProvider(repo);
      await settings.initialize(observeDate: false);
      final ambient = FakeAudio();
      final theme = ThemeAudioProvider(ambient, settings);
      await theme.synchronize();
      expect(theme.playing, isFalse);
      final sound = FakeIntroAudio();
      final intro = IntroAudioProvider(sound, theme, settings);
      await intro.startWelcome(Season.christmas);
      expect(theme.playing, isFalse);
      expect(sound.events, ['play:sounds/christmas.mp3']);
      await intro.stop();
      expect(sound.events.last, 'stop');
      expect(theme.playing, isFalse);
      await settings.setMuted(true);
      await intro.startWelcome(Season.normal);
      expect(sound.events.where((e) => e.startsWith('play:')).length, 1);
      intro.dispose();
      await Future<void>.delayed(Duration.zero);
      theme.dispose();
      settings.dispose();
    },
  );
  test('Intro sound preference survives restart', () async {
    final repo = SharedPreferencesRepository(storage: MemoryStore());
    final settings = SettingsProvider(repo);
    await settings.setIntroSound(true);
    expect((await repo.read()).introSound, isTrue);
    settings.dispose();
  });
  test('Intro sound does not start when themed audio cannot stop', () async {
    final repository = SharedPreferencesRepository(storage: MemoryStore());
    await repository.save(
      const AppPreferences(
        manualSeason: Season.halloween,
        themeAudio: true,
        introSound: true,
        muted: false,
      ),
    );
    final settings = SettingsProvider(repository);
    await settings.initialize(observeDate: false);
    final backend = FakeAudio();
    final theme = ThemeAudioProvider(backend, settings);
    await theme.synchronize();
    backend.failStop = true;
    final sound = FakeIntroAudio();
    final intro = IntroAudioProvider(sound, theme, settings);
    await intro.start(Season.halloween);
    expect(sound.events, isEmpty);
    backend.failStop = false;
    intro.dispose();
    await Future<void>.delayed(Duration.zero);
    theme.dispose();
    settings.dispose();
  });
  test('Preview blocks playback then restores manual pause', () async {
    final playback = PlaybackCoordinator(
      createController: (v) => FakePlayer(v.videoUrl),
      initiallyMuted: false,
    );
    await playback.select([
      const VideoPost(caption: 'Test', videoUrl: 'asset.mp4'),
    ], 0);
    await playback.setIntroActive(true);
    expect(playback.current!.value.isPlaying, isFalse);
    await playback.setIntroActive(false);
    expect(playback.current!.value.isPlaying, isTrue);
    await playback.togglePause();
    await playback.setIntroActive(true);
    await playback.setIntroActive(false);
    expect(playback.current!.value.isPlaying, isFalse);
    playback.dispose();
    await Future<void>.delayed(Duration.zero);
  });
  for (final season in Season.values) {
    testWidgets(
      '${season.name} intro completes with its real logo and no animation errors',
      (tester) async {
        var completions = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SeasonIntro(
                season: season,
                onComplete: () => completions++,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(TokTikLogo), findsOneWidget);
        expect(
          tester.widget<TokTikLogo>(find.byType(TokTikLogo)).season,
          season,
        );
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 350));
        }
        expect(completions, 1);
        expect(tester.takeException(), isNull);
        expect(BrandAssets.logo(season), contains(season.name));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Reduced-motion Christmas uses the complete decorated logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SeasonIntro(season: Season.christmas, onComplete: () {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<TokTikLogo>(find.byType(TokTikLogo)).decorated,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
