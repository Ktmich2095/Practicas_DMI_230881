import '../entities/season.dart';

abstract class LauncherIconRepository {
  bool get supported;
  Future<void> apply(Season season);
}
