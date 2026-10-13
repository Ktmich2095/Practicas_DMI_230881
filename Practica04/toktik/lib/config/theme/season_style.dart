import 'package:flutter/material.dart';

import '../../domain/entities/season.dart';

class SeasonStyle {
  Duration get animationDuration => switch (audioAsset) {
    'audio/halloween.wav' => const Duration(milliseconds: 280),
    'audio/christmas.wav' => const Duration(milliseconds: 420),
    'audio/valentine.wav' => const Duration(milliseconds: 550),
    _ => const Duration(milliseconds: 220),
  };
  final Color primary, accent, background;
  final IconData icon;
  final String fontFamily;
  final String? audioAsset;
  const SeasonStyle(
    this.primary,
    this.accent,
    this.background,
    this.icon,
    this.fontFamily,
    this.audioAsset,
  );
  static SeasonStyle of(Season season) => switch (season) {
    Season.normal => const SeasonStyle(
      Color(0xFF5DE2D2),
      Color(0xFFFF527C),
      Color(0xFF101014),
      Icons.auto_awesome,
      'sans-serif',
      null,
    ),
    Season.halloween => const SeasonStyle(
      Color(0xFFFFA040),
      Color(0xFFBD86FF),
      Color(0xFF161020),
      Icons.nightlight_round,
      'monospace',
      'audio/halloween.wav',
    ),
    Season.christmas => const SeasonStyle(
      Color(0xFFFFD36A),
      Color(0xFFF75B66),
      Color(0xFF0B2821),
      Icons.forest_rounded,
      'serif',
      'audio/christmas.wav',
    ),
    Season.valentine => const SeasonStyle(
      Color(0xFFFF90BD),
      Color(0xFFFF526A),
      Color(0xFF28111D),
      Icons.favorite_rounded,
      'serif',
      'audio/valentine.wav',
    ),
  };
}
