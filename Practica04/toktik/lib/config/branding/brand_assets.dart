import 'package:flutter/material.dart';

import '../../domain/entities/season.dart';

/// All identity asset paths and intro timing live here; no seasonal date logic.
class BrandAssets {
  static String logo(Season season, {bool decorated = true}) =>
      'assets/branding/${decorated ? 'logo' : 'mark'}_${season.name}.png';
  // AssetSource adds the assets/ prefix. Files are optional until supplied.
  static String introAudio(Season season) => 'sounds/${season.name}.mp3';
  static Duration duration(Season season) => Duration(
    milliseconds: switch (season) {
      Season.normal => 2800,
      Season.halloween => 3400,
      Season.christmas => 3600,
      Season.valentine => 3200,
    },
  );
  static List<Color> background(Season season) => switch (season) {
    Season.normal => const [Colors.black, Colors.black],
    Season.halloween => const [Color(0xFF030207), Color(0xFF251039)],
    Season.christmas => const [Color(0xFF071424), Color(0xFF0B3028)],
    Season.valentine => const [Color(0xFF41152C), Color(0xFF9C3157)],
  };
}
