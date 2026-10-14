import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/video_source.dart';
import 'settings_provider.dart';
import 'discover_provider.dart';
import 'season_identity_provider.dart';

class StartupProvider extends ChangeNotifier {
  final SettingsProvider settings;
  final DiscoverProvider discover;
  final SeasonIdentityProvider identity;
  bool settingsReady = false, ready = false, loading = false, _disposed = false;
  String status = 'Preparando TokTik', error = '';
  StartupProvider(this.settings, this.discover, this.identity);
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (loading || _disposed) return;
    loading = true;
    ready = false;
    error = '';
    _emit();
    await settings.initialize();
    if (_disposed) return;
    settingsReady = true;
    status = 'Preparando tus videos y favoritos';
    _emit();
    unawaited(identity.synchronize());
    try {
      await discover
          .changeSource(settings.preferences.source)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // The generation guard in Discover discards the late remote response.
      status = 'La fuente tarda demasiado. Cargando videos locales';
      _emit();
      try {
        await discover
            .changeSource(VideoSource.local)
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        error = 'No se pudieron preparar los videos. Puedes reintentar o entrar al feed.';
      }
    } catch (_) {
      error = 'No se pudieron preparar los videos. Puedes reintentar o entrar al feed.';
    }
    if (_disposed) return;
    ready = error.isEmpty;
    loading = false;
    status = 'TokTik está listo';
    _emit();
  }

  void continueToFeed() {
    ready = true;
    loading = false;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
