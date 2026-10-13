import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/repositories/preferences_repository.dart';

class SettingsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PreferencesRepository repository;
  final DateTime Function() clock;
  AppPreferences preferences = const AppPreferences();
  String? error;
  bool saving = false, _disposed = false;
  late DateTime _date;
  Timer? _midnight;
  SettingsProvider(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    _date = this.clock();
  }
  Season get season => preferences.manualSeason ?? Season.forDate(_date);
  Future<void> initialize({bool observeDate = true}) async {
    try {
      preferences = await repository.read();
    } catch (_) {
      error = 'No se pudieron recuperar las preferencias. Se usan valores iniciales.';
    }
    if (observeDate) {
      WidgetsBinding.instance.addObserver(this);
      _scheduleMidnight();
    }
    if (!_disposed) notifyListeners();
  }

  void refreshDate() {
    _date = clock();
    if (!_disposed) notifyListeners();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = clock();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        refreshDate();
        if (!_disposed) _scheduleMidnight();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshDate();
      _scheduleMidnight();
    }
  }

  Future<bool> _save(AppPreferences next) async {
    if (saving || _disposed) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await repository.save(next);
      preferences = next;
    } catch (_) {
      error = 'No se pudo guardar la preferencia. Intenta nuevamente.';
    }
    saving = false;
    if (!_disposed) notifyListeners();
    return error == null;
  }

  Future<bool> selectSource(VideoSource source) =>
      _save(preferences.copyWith(source: source));
  Future<bool> selectSeason(Season? season) => _save(
    preferences.copyWith(manualSeason: season, automaticSeason: season == null),
  );
  Future<bool> setMuted(bool value) =>
      _save(preferences.copyWith(muted: value));
  Future<bool> setThemeAudio(bool value) =>
      _save(preferences.copyWith(themeAudio: value));
  @override
  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
