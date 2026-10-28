import 'package:meta/meta.dart';

/// A calendar date with no time or time zone: due dates, billing days,
/// paid-until dates.
///
/// Stored as `yyyy-MM-dd` text. Keeping these out of UTC means a bill due on
/// the 5th stays on the 5th when the user travels or the zone changes.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError('Invalid date $year-$month-$day');
    }
  }

  /// Parses `yyyy-MM-dd`.
  factory LocalDate.parse(String iso) {
    final match = _iso.firstMatch(iso);
    if (match == null) throw FormatException('Not a yyyy-MM-dd date', iso);
    return LocalDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  /// The date part of [dateTime] as it reads in [dateTime]'s own zone.
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  static final _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// 1 = Monday … 7 = Sunday, as [DateTime.weekday].
  int get weekday => _utc.weekday;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Days since 1970-01-01. Useful for ordering and day arithmetic.
  int get epochDay =>
      _utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static LocalDate fromEpochDay(int days) => LocalDate.fromDateTime(
    DateTime.fromMillisecondsSinceEpoch(
      days * Duration.millisecondsPerDay,
      isUtc: true,
    ),
  );

  LocalDate addDays(int days) => fromEpochDay(epochDay + days);

  /// Adds calendar months. A day that does not exist in the target month
  /// becomes that month's last day (Jan 31 + 1 month = Feb 28 or 29).
  ///
  /// Always compute repeated dates from the original anchor
  /// (`anchor.addMonths(k)`), never by chaining, or Jan 31 → Feb 28 → Mar 28
  /// would lose the 31st for good.
  LocalDate addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final last = daysInMonth(y, m);
    return LocalDate(y, m, day > last ? last : day);
  }

  LocalDate addYears(int years) => addMonths(years * 12);

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  static int daysInMonth(int year, int month) => switch (month) {
    2 => _isLeap(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  static bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) => epochDay.compareTo(other.epochDay);

  bool operator <(LocalDate other) => compareTo(other) < 0;
  bool operator <=(LocalDate other) => compareTo(other) <= 0;
  bool operator >(LocalDate other) => compareTo(other) > 0;
  bool operator >=(LocalDate other) => compareTo(other) >= 0;

  static LocalDate max(LocalDate a, LocalDate b) => a >= b ? a : b;

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// `yyyy-MM-dd`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
