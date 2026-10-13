import 'package:flutter/material.dart';

import '../../domain/entities/season.dart';
import 'season_style.dart';

class AppTheme {
  ThemeData getTheme([Season season = Season.normal]) {
    final style = SeasonStyle.of(season);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: style.background,
      fontFamily: style.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: style.primary,
        brightness: Brightness.dark,
        primary: style.primary,
        secondary: style.accent,
        surface: style.background,
      ),
    );
  }
}
