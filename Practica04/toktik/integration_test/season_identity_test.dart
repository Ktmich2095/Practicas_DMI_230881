import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:toktik_app/main.dart' as app;
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/infrastructure/repositories/android_launcher_icon_repository.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/season_identity_provider.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';
import 'package:toktik_app/presentation/screens/discover/discover_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: real feed, all launcher seasons and persisted preferences',
    (tester) async {
      final repository = SharedPreferencesRepository();
      final previous = await repository.read();
      await repository.save(
        const AppPreferences(
          source: VideoSource.local,
          manualSeason: Season.normal,
        ),
      );
      try {
        await app.main();
        for (
          var i = 0;
          i < 65 && find.byType(DiscoverScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(DiscoverScreen), findsOneWidget);
        final context = tester.element(find.byType(DiscoverScreen));
        final settings = context.read<SettingsProvider>();
        final identity = context.read<SeasonIdentityProvider>();
        for (final season in Season.values) {
          await settings.selectSeason(season);
          await identity.synchronize();
          await tester.pump();
          final states = await AndroidLauncherIconRepository.channel
              .invokeMapMethod<String, bool>('getStates');
          expect(states!.values.where((enabled) => enabled).length, 1);
          expect(states[season.name], isTrue);
          expect((await repository.read()).manualSeason, season);
        }
        final playback = context.read<PlaybackCoordinator>();
        for (
          var i = 0;
          i < 30 && playback.current?.value.isInitialized != true;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(playback.current!.value.isInitialized, isTrue);
        await playback.togglePause();
        expect(playback.current!.value.isPlaying, isFalse);
        await playback.togglePause();
        expect(playback.current!.value.isPlaying, isTrue);
      } finally {
        await repository.save(previous);
        if (find.byType(DiscoverScreen).evaluate().isNotEmpty) {
          final context = tester.element(find.byType(DiscoverScreen));
          await context.read<SettingsProvider>().initialize(observeDate: false);
          await context.read<SeasonIdentityProvider>().synchronize();
        }
      }
    },
  );
}
