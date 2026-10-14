import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/season.dart';
import '../../domain/repositories/launcher_icon_repository.dart';
import 'settings_provider.dart';

/// One season state drives widgets and the native launcher. Serial native writes.
class SeasonIdentityProvider extends ChangeNotifier {
  final SettingsProvider settings;
  final LauncherIconRepository repository;
  Season? _applied;
  bool _disposed = false;
  String? error;
  Future<void> _queue = Future.value();
  SeasonIdentityProvider(this.settings, this.repository) {
    settings.addListener(_changed);
  }
  void _changed() {
    if (settings.initialized) unawaited(synchronize());
  }

  Future<void> synchronize() {
    _queue = _queue.then((_) async {
      if (_disposed || !settings.initialized || !repository.supported) return;
      final season = settings.season;
      if (_applied == season && error == null) return;
      try {
        await repository.apply(season).timeout(const Duration(seconds: 4));
        _applied = season;
        error = null;
      } catch (_) {
        error = 'El launcher no pudo actualizar su ícono. Puedes reintentar.';
      }
      if (!_disposed) notifyListeners();
    });
    return _queue;
  }

  @override
  void dispose() {
    _disposed = true;
    settings.removeListener(_changed);
    super.dispose();
  }
}
