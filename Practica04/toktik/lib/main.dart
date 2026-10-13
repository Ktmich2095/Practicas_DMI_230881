import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'config/theme/app_theme.dart';
import 'domain/entities/season.dart';
import 'domain/repositories/video_catalog_repository.dart';
import 'infrastructure/datasources/json_api_client.dart';
import 'infrastructure/datasources/coverr_datasource.dart';
import 'infrastructure/datasources/pixabay_datasource.dart';
import 'infrastructure/datasources/archive_datasource.dart';
import 'infrastructure/datasources/local_assets_datasource.dart';
import 'infrastructure/repositories/preferences_favorites_repository.dart';
import 'infrastructure/repositories/preferences_statistics_repository.dart';
import 'infrastructure/repositories/shared_preferences_repository.dart';
import 'infrastructure/repositories/fallback_video_repository.dart';
import 'infrastructure/repositories/audioplayers_theme_repository.dart';
import 'presentation/providers/discover_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_audio_provider.dart';
import 'presentation/providers/playback_coordinator.dart';
import 'presentation/screens/discover/discover_screen.dart';
import 'presentation/screens/startup/startup_screen.dart';
import 'presentation/providers/startup_provider.dart';
import 'presentation/providers/season_identity_provider.dart';
import 'presentation/providers/intro_audio_provider.dart';
import 'infrastructure/repositories/android_launcher_icon_repository.dart';
import 'infrastructure/repositories/audioplayers_intro_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider(SharedPreferencesRepository());
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
            statisticsRepository: PreferencesStatisticsRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ThemeAudioProvider(AudioplayersThemeRepository(), settings),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaybackCoordinator(
            onQualifiedView: context.read<DiscoverProvider>().recordView,
            initiallyMuted: settings.preferences.muted,
            persistMuted: settings.setMuted,
            coordinateAudio: context.read<ThemeAudioProvider>().setVideoAudible,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SeasonIdentityProvider(settings, AndroidLauncherIconRepository()),
        ),
        Provider<IntroAudioProvider>(
          create: (context) => IntroAudioProvider(
            AudioplayersIntroRepository(),
            context.read<ThemeAudioProvider>(),
            settings,
          ),
          dispose: (_, audio) => audio.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => StartupProvider(
            settings,
            context.read<DiscoverProvider>(),
            context.read<SeasonIdentityProvider>(),
          ),
        ),
      ],
      child: const MyApp(home: StartupScreen()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, this.home = const DiscoverScreen()});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TokTik',
    debugShowCheckedModeBanner: false,
    theme: AppTheme().getTheme(
      context.watch<SettingsProvider>().initialized
          ? context.watch<SettingsProvider>().season
          : Season.normal,
    ),
    home: home,
  );
}
