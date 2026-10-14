import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/season.dart';
import '../../domain/repositories/launcher_icon_repository.dart';

class AndroidLauncherIconRepository implements LauncherIconRepository {
  static const channel = MethodChannel('toktik/season_identity');
  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  Future<void> apply(Season season) async {
    if (!supported) return;
    await channel.invokeMethod<void>('setSeason', {'season': season.name});
  }
}
