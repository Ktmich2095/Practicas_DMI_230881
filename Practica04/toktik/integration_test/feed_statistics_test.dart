import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toktik_app/main.dart' as app;
import 'package:toktik_app/domain/entities/app_preferences.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';
import 'package:toktik_app/presentation/screens/discover/discover_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: real video playback and synchronized metrics across three feeds',
    (tester) async {
      final preferences = SharedPreferencesRepository();
      final previous = await preferences.read();
      final storage = SharedPreferencesAsync();
      final backup = <String, String?>{};
      for (final key in [
        'toktik.favorite_catalog.v2',
        'toktik.view_increments.v1',
      ]) {
        backup[key] = await storage.getString(key);
      }
      await preferences.save(
        const AppPreferences(source: VideoSource.local, introSound: false),
      );
      try {
        await app.main();
        for (
          var i = 0;
          i < 300 && find.byType(DiscoverScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(DiscoverScreen), findsOneWidget);
        final context = tester.element(find.byType(DiscoverScreen));
        final playback = context.read<PlaybackCoordinator>();
        final feed = context.read<DiscoverProvider>();
        Future<void> waitForPlayback() async {
          for (
            var i = 0;
            i < 650 && playback.current?.value.isPlaying != true;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(playback.current?.value.isInitialized, isTrue);
          expect(playback.current?.value.isPlaying, isTrue);
          expect(
            playback.controllers.values.where((p) => p.value.isPlaying).length,
            1,
          );
        }

        await waitForPlayback();
        final video = feed.videos.first;
        final beforeViews = feed.views(video);
        for (var i = 0; i < 120 && feed.views(video) == beforeViews; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(feed.views(video), beforeViews + 1);
        if (feed.isFavorite(video)) await feed.toggleFavorite(video);
        final baseLikes = feed.likes(video);
        await feed.toggleFavorite(video);
        await tester.pump();
        await tester.tap(find.text('Discover'));
        await tester.pump();
        await waitForPlayback();
        await tester.tap(find.text('Favorites'));
        await tester.pump();
        await waitForPlayback();
        expect(feed.likes(video), baseLikes + 1);
        expect(feed.views(video), beforeViews + 1);
        await tester.tap(find.text('For You'));
        await tester.pump();
        await waitForPlayback();
        expect(playback.current!.dataSource, video.videoUrl);
        await feed.recordView(
          video,
        ); // Await outstanding persistence; no extra view.
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      } finally {
        await preferences.save(previous);
        for (final entry in backup.entries) {
          if (entry.value == null) {
            await storage.remove(entry.key);
          } else {
            await storage.setString(entry.key, entry.value!);
          }
        }
      }
    },
  );
}
