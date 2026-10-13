/// Calendar configuration, independent of Flutter. Intervals include both ends.
class SeasonRange {
  final String name;
  final int startMonth, startDay, endMonth, endDay;
  const SeasonRange(
    this.name,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
  );
  bool contains(DateTime date) {
    final day = date.month * 100 + date.day;
    final start = startMonth * 100 + startDay, end = endMonth * 100 + endDay;
    return start <= end
        ? day >= start && day <= end
        : day >= start || day <= end;
  }
}

class SeasonCalendar {
  static const ranges = [
    SeasonRange('halloween', 10, 1, 10, 31),
    SeasonRange('christmas', 12, 1, 12, 31),
    SeasonRange('valentine', 2, 1, 2, 14),
  ];
  static String resolve(DateTime date) {
    for (final range in ranges) {
      if (range.contains(date)) return range.name;
    }
    return 'normal';
  }
}
