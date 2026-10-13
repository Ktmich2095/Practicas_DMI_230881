import 'package:shared_preferences/shared_preferences.dart';

/// Injectable storage boundary; production uses SharedPreferencesAsync.
abstract class PreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> values);
}

class SharedPreferencesStore implements PreferencesStore {
  final SharedPreferencesAsync preferences = SharedPreferencesAsync();
  @override
  Future<String?> getString(String key) => preferences.getString(key);
  @override
  Future<void> setString(String key, String value) =>
      preferences.setString(key, value);
  @override
  Future<List<String>?> getStringList(String key) =>
      preferences.getStringList(key);
  @override
  Future<void> setStringList(String key, List<String> values) =>
      preferences.setStringList(key, values);
}
