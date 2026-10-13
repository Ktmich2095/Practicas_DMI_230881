import '../entities/app_preferences.dart';

abstract class PreferencesRepository {
  Future<AppPreferences> read();
  Future<void> save(AppPreferences preferences);
}
