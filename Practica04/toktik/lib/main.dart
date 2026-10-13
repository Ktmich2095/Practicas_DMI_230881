import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'config/theme/app_theme.dart';
import 'domain/repositories/video_catalog_repository.dart';
import 'infrastructure/datasources/json_api_client.dart';
import 'infrastructure/datasources/coverr_datasource.dart';
import 'infrastructure/datasources/pixabay_datasource.dart';
import 'infrastructure/datasources/archive_datasource.dart';
import 'infrastructure/datasources/local_assets_datasource.dart';
import 'infrastructure/repositories/preferences_favorites_repository.dart';
import 'infrastructure/repositories/shared_preferences_repository.dart';
import 'infrastructure/repositories/fallback_video_repository.dart';
import 'infrastructure/repositories/audioplayers_theme_repository.dart';
import 'presentation/providers/discover_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_audio_provider.dart';
import 'presentation/providers/playback_coordinator.dart';
import 'presentation/screens/discover/discover_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider(SharedPreferencesRepository());
  await settings.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings),
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider<VideoCatalogRepository>(
          create: (context) {
            final api = JsonApiClient(context.read<http.Client>());
            return FallbackVideoRepository([
              CoverrDatasource(api),
              PixabayDatasource(api),
              ArchiveDatasource(api),
              LocalAssetsDatasource(),
            ]);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => DiscoverProvider(
            repository: context.read<VideoCatalogRepository>(),
            favoritesRepository: PreferencesFavoritesRepository(),
          )..changeSource(settings.preferences.source),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ThemeAudioProvider(AudioplayersThemeRepository(), settings),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaybackCoordinator(
            initiallyMuted: settings.preferences.muted,
            persistMuted: settings.setMuted,
            coordinateAudio: context.read<ThemeAudioProvider>().setVideoAudible,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TokTik',
    debugShowCheckedModeBanner: false,
    theme: AppTheme().getTheme(context.watch<SettingsProvider>().season),
    home: const DiscoverScreen(),
  );
}
