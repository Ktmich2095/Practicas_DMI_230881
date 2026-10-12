import 'package:flutter/material.dart';

const colorList = <color>[
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.amber,
];

class AppTheme {
  final int selectedColor;

  AppTheme({
    this.selectedColor=0
  }):assert(selectedColor>=0,'Selected color must be greater then 0'),
     assert(selectedColor<colorList.length,
     'Selected color must be less or quial than ${colorList.length-1}');

     ThemeData getTheme() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorList[selectedColor],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      )
     );
}