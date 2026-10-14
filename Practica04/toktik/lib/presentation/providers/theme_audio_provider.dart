import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/repositories/theme_audio_repository.dart';

import 'settings_provider.dart';

class ThemeAudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ThemeAudioRepository repository;
  final SettingsProvider settings;
  bool _disposed = false;
  String? _playingAsset, error;
  Future<void> _queue = Future.value();
  bool get playing => _playingAsset != null;
  ThemeAudioProvider(this.repository, this.settings) {
    settings.addListener(_settingsChanged);
    WidgetsBinding.instance.addObserver(this);
  }
  void _settingsChanged() {
    unawaited(synchronize());
  }

  Future<void> setVideoAudible(bool audible) async {
    await synchronize();
    if (audible && error != null) {
      throw StateError('No se pudo detener el audio temático');
    }
  }

  Future<void> setForeground(bool active) {
    return synchronize();
  }

  Future<void> setIntroActive(bool active) async {
    await synchronize();
    if (active && error != null) {
      throw StateError(
        'No se pudo detener el audio temático antes de la intro',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(setForeground(state == AppLifecycleState.resumed));
  }

  Future<void> synchronize() {
    _queue = _queue
        .then((_) async {
          if (_disposed) return;
          // Legacy ambient audio is disabled, even for saved themeAudio=true.
          // Keep the stop barrier used by video and intro coordination.
          await repository.stop();
          _playingAsset = null;
          error = null;
          if (!_disposed) notifyListeners();
        })
        .catchError((Object _) {
          _playingAsset = null;
          error = 'Audio temático no disponible.';
          if (!_disposed) notifyListeners();
        });
    return _queue;
  }

  @override
  void dispose() {
    _disposed = true;
    settings.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      _queue.then((_) async {
        await repository.stop();
        await repository.dispose();
      }),
    );
    super.dispose();
  }
}
