import 'dart:convert';

import '../storage/preferences_store.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/repositories/preferences_repository.dart';

class SharedPreferencesRepository implements PreferencesRepository {
  final PreferencesStore storage;
  SharedPreferencesRepository({PreferencesStore? storage})
    : storage = storage ?? SharedPreferencesStore();
  @override
  Future<AppPreferences> read() async {
    final raw = await storage.getString('toktik.preferences.v1');
    if (raw == null) return const AppPreferences();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AppPreferences(
      source: VideoSource.parse(data['source']),
      manualSeason: Season.parse(data['season']),
      muted: data['muted'] != false,
      themeAudio: data['themeAudio'] == true,
    );
  }

  @override
  Future<void> save(AppPreferences preferences) => storage.setString(
    'toktik.preferences.v1',
    jsonEncode({
      'source': preferences.source.name,
      'season': preferences.manualSeason?.name,
      'muted': preferences.muted,
      'themeAudio': preferences.themeAudio,
    }),
  );
}
