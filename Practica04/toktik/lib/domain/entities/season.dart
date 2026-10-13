import 'season_calendar.dart';

enum Season {
  normal('Normal'),
  halloween('Halloween'),
  christmas('Navidad'),
  valentine('San Valentín');

  final String label;
  const Season(this.label);
  static Season forDate(DateTime date) {
    return parse(SeasonCalendar.resolve(date)) ?? normal;
  }

  static Season? parse(Object? name) {
    for (final season in values) {
      if (season.name == name) return season;
    }
    return null;
  }
}
