import 'package:flutter/material.dart';

const Color _customColor = Color(0xFF8E24AA);

const List<Color> _colorThemes = [
  _customColor,
  Color(0xFF6A1B9A),
  Colors.purple,
  Color(0xFF7E57C2),
  Color(0xFF5E35B1),
  Color(0xFFAB47BC),
];

class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0})
    : assert(
        selectedColor >= 0 && selectedColor < _colorThemes.length - 1,
        'Colors must be between 0 and ${_colorThemes.length}',
      );

  ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _colorThemes[selectedColor],
      brightness: Brightness.dark,
    );
  }
}
