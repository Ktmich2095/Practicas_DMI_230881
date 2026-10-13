import 'package:toktik_app/infrastructure/storage/preferences_store.dart';

class MemoryStore implements PreferencesStore {
  final Map<String, Object> values = {};
  bool fail = false;
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('storage unavailable');
    values[key] = value;
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      values[key] as List<String>?;
  @override
  Future<void> setStringList(String key, List<String> value) async {
    if (fail) throw StateError('storage unavailable');
    values[key] = value;
  }
}
