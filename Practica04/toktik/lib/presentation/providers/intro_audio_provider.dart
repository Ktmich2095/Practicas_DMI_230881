import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/branding/brand_assets.dart';
import '../../domain/entities/season.dart';
import '../../domain/repositories/intro_audio_repository.dart';
import 'settings_provider.dart';
import 'theme_audio_provider.dart';

class IntroAudioProvider with WidgetsBindingObserver {
  final IntroAudioRepository repository;
  final ThemeAudioProvider themeAudio;
  final SettingsProvider settings;
  bool _foreground = true, _active = false, _disposed = false;
  Future<void> _queue = Future.value();
  IntroAudioProvider(this.repository, this.themeAudio, this.settings) {
    WidgetsBinding.instance.addObserver(this);
  }
  Future<void> start(Season season) {
    _active = true;
    _queue = _queue
        .then((_) async {
          if (_disposed || !_active) return;
          await themeAudio.setIntroActive(true);
          if (_foreground &&
              settings.preferences.introSound &&
              !settings.preferences.muted &&
              _active) {
            await repository.playOnce(BrandAssets.introAudio(season));
          }
        })
        .catchError((Object _) {}); // Optional sound must never block startup.
    return _queue;
  }

  Future<void> stop() {
    _active = false;
    _queue = _queue
        .then((_) async {
          await repository.stop();
          await themeAudio.setIntroActive(false);
        })
        .catchError((Object _) {});
    return _queue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _queue = _queue.then((_) => repository.stop()).catchError((Object _) {});
    }
  }

  void dispose() {
    _disposed = true;
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      _queue.then((_) async {
        await repository.stop();
        await repository.dispose();
      }),
    );
  }
}
