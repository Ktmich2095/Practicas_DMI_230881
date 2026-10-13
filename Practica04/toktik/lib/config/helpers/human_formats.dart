class HumanFormats {
  static String humanReadableNumber(double number) {
    final value = number.clamp(0, 1000000000000000).floor();
    for (final entry in {1000000000: 'B', 1000000: 'M', 1000: 'K'}.entries) {
      if (value >= entry.key) {
        final scaled = (value * 10 ~/ entry.key) / 10;
        return '${scaled == scaled.floorToDouble() ? scaled.toInt() : scaled}${entry.value}';
      }
    }
    return '$value';
  }
}
