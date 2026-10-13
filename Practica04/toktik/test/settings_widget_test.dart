import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/domain/entities/video_batch.dart';
import 'package:toktik_app/domain/entities/season.dart';
import 'package:toktik_app/domain/repositories/video_catalog_repository.dart';
import 'package:toktik_app/infrastructure/repositories/shared_preferences_repository.dart';
import 'package:toktik_app/infrastructure/repositories/preferences_favorites_repository.dart';
import 'package:toktik_app/presentation/providers/settings_provider.dart';
import 'package:toktik_app/presentation/providers/discover_provider.dart';
import 'package:toktik_app/presentation/providers/theme_audio_provider.dart';
import 'package:toktik_app/main.dart';

import 'support/memory_store.dart';
import 'preferences_themes_test.dart' show FakeAudio;

class EmptyCatalog implements VideoCatalogRepository {
  @override
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0}) async =>
      VideoBatch(videos: const [], source: selected);
}

void main() {
  testWidgets(
    'All tabs, source selection and manual theme work on narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      final settings = SettingsProvider(
        SharedPreferencesRepository(storage: store),
        clock: () => DateTime(2026, 7, 1),
      );
      await settings.initialize(observeDate: false);
      final feed = DiscoverProvider(
        repository: EmptyCatalog(),
        favoritesRepository: PreferencesFavoritesRepository(storage: store),
      );
      await feed.loadNextPage();
      final audio = ThemeAudioProvider(FakeAudio(), settings);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: feed),
            ChangeNotifierProvider.value(value: audio),
          ],
          child: const MyApp(),
        ),
      );
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No hay contenido'), findsOneWidget);
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Aún no tienes favoritos.'), findsOneWidget);
      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fuentes y temas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aleatoria').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Videos locales').last);
      await tester.pumpAndSettle();
      expect(settings.preferences.source, VideoSource.local);
      expect(feed.selectedSource, VideoSource.local);
      await tester.tap(find.text('Automático'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Navidad').last);
      await tester.pumpAndSettle();
      expect(settings.season, Season.christmas);
      expect(find.text('Tema actual: Navidad'), findsOneWidget);
      await tester.tap(find.text('Volver a Aleatoria'));
      await tester.pumpAndSettle();
      expect(settings.preferences.source, VideoSource.random);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      audio.dispose();
      feed.dispose();
      settings.dispose();
      await tester.pump();
    },
  );
}
