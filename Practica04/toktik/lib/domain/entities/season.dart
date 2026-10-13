enum Season {
  normal('Normal'),
  halloween('Halloween'),
  christmas('Navidad'),
  valentine('San Valentín');

  final String label;
  const Season(this.label);
  static Season forDate(DateTime date) {
    if (date.month == 10) return halloween;
    if (date.month == 12) return christmas;
    if (date.month == 2 && date.day <= 14) return valentine;
    return normal;
  }

  static Season? parse(Object? name) {
    for (final season in values) {
      if (season.name == name) return season;
    }
    return null;
  }
}
