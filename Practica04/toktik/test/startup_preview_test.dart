import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/domain/entities/video_batch.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/domain/entities/video_post.dart';
import 'package:toktik_app/domain/repositories/preferences_repository.dart';
import 'package:toktik_app/domain/repositories/video_catalog_repository.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/infrastructure/repositories/preferences_favorites_repository.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';
import 'package:toktik_app/presentation/providers/startup_provider.dart';
import 'package:toktik_app/presentation/providers/season_identity_provider.dart';
import 'package:toktik_app/presentation/providers/intro_audio_provider.dart';
import 'package:toktik_app/presentation/providers/theme_audio_provider.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';
import 'package:toktik_app/presentation/screens/startup/startup_screen.dart';
import 'package:toktik_app/presentation/screens/startup/intro_preview_screen.dart';
import 'package:toktik_app/presentation/screens/discover/discover_screen.dart';
import 'package:toktik_app/presentation/widgets/branding/toktik_logo.dart';

import 'support/memory_store.dart';
import 'identity_test.dart' show FakeIcons, FakeIntroAudio;
import 'preferences_themes_test.dart' show FakeAudio;
import 'playback_coordinator_test.dart' show FakePlayer;

class DeferredPreferences implements PreferencesRepository {
  final ready = Completer<AppPreferences>();
  @override
  Future<AppPreferences> read() => ready.future;
  @override
  Future<void> save(AppPreferences preferences) async {}
}

class DeferredCatalog implements VideoCatalogRepository {
  final ready = Completer<VideoBatch>();
  @override
  Future<VideoBatch> fetch(VideoSource source, {int page = 0}) => ready.future;
}

void main() {
  testWidgets(
    'Startup waits for real preferences and load; never flashes the wrong logo',
    (tester) async {
      final preferences = DeferredPreferences();
      final catalog = DeferredCatalog();
      final settings = SettingsProvider(preferences);
      final feed = DiscoverProvider(
        repository: catalog,
        favoritesRepository: PreferencesFavoritesRepository(
          storage: MemoryStore(),
        ),
      );
      final identity = SeasonIdentityProvider(settings, FakeIcons());
      final theme = ThemeAudioProvider(FakeAudio(), settings);
      final sound = FakeIntroAudio();
      final audio = IntroAudioProvider(sound, theme, settings);
      final startup = StartupProvider(settings, feed, identity);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: feed),
            ChangeNotifierProvider.value(value: startup),
            Provider.value(value: audio),
          ],
          child: const MaterialApp(home: StartupScreen()),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('preferences-loading')), findsOneWidget);
      expect(find.byType(TokTikLogo), findsNothing);
      expect(sound.events, isEmpty);
      preferences.ready.complete(
        const AppPreferences(
          manualSeason: Season.christmas,
          source: VideoSource.local,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<TokTikLogo>(find.byType(TokTikLogo)).season,
        Season.christmas,
      );
      expect(find.byType(DiscoverScreen), findsNothing);
      expect(sound.events, ['play:sounds/christmas.mp3']);
      catalog.ready.complete(
        const VideoBatch(videos: [], source: VideoSource.local),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(sound.events.last, 'stop');
      expect(
        sound.events.where((event) => event.startsWith('play:')).length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      startup.dispose();
      identity.dispose();
      feed.dispose();
      audio.dispose();
      await tester.pump();
      theme.dispose();
      settings.dispose();
      await tester.pump();
    },
  );
  testWidgets(
    'Preview closes early, stops its sound and resumes the previous video',
    (tester) async {
      final repository = SharedPreferencesRepository(storage: MemoryStore());
      await repository.save(
        const AppPreferences(
          manualSeason: Season.valentine,
          introSound: true,
          muted: false,
        ),
      );
      final settings = SettingsProvider(repository);
      await settings.initialize(observeDate: false);
      final theme = ThemeAudioProvider(FakeAudio(), settings);
      final sound = FakeIntroAudio();
      final audio = IntroAudioProvider(sound, theme, settings);
      final playback = PlaybackCoordinator(
        createController: (v) => FakePlayer(v.videoUrl),
      );
      await playback.select([
        const VideoPost(caption: 'Test', videoUrl: 'test.mp4'),
      ], 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => IntroPreviewScreen.open(
                  context,
                  Season.valentine,
                  playback,
                  audio,
                ),
                child: const Text('Preview'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(IntroPreviewScreen), findsOneWidget);
      expect(playback.current!.value.isPlaying, isFalse);
      await tester.tap(find.text('Cerrar vista previa'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroPreviewScreen), findsNothing);
      expect(playback.current!.value.isPlaying, isTrue);
      expect(sound.events.last, 'stop');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      playback.dispose();
      audio.dispose();
      await tester.pump();
      theme.dispose();
      settings.dispose();
      await tester.pump();
    },
  );
}
