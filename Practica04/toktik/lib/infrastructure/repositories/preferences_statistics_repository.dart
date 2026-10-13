import 'dart:convert';

import '../../domain/repositories/video_statistics_repository.dart';
import '../storage/preferences_store.dart';

class PreferencesStatisticsRepository implements VideoStatisticsRepository {
  final PreferencesStore storage;
  PreferencesStatisticsRepository({PreferencesStore? storage})
    : storage = storage ?? SharedPreferencesStore();
  static const key = 'toktik.view_increments.v1';
  @override
  Future<Map<String, int>> readViewIncrements() async {
    final raw = await storage.getString(key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        if (entry.value is int && entry.value >= 0 && entry.value <= 1000000000)
          entry.key: entry.value as int,
    };
  }

  @override
  Future<void> saveViewIncrements(Map<String, int> increments) =>
      storage.setString(key, jsonEncode(increments));
}
