import 'package:intl/intl.dart';

/// Centralized date formatting so every screen renders dates consistently.
abstract class DateFormatter {
  DateFormatter._();

  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _weekdayDayMonth = DateFormat('EEE, d MMM');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String full(DateTime date) => _dayMonthYear.format(date);
  static String short(DateTime date) => _dayMonth.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String weekdayShort(DateTime date) => _weekdayDayMonth.format(date);
  static String time(DateTime date) => _time.format(date);
  static String iso(DateTime date) => _isoDate.format(date);

  /// Human-friendly relative label: Today / Yesterday / "12 Jun 2026"
  static String relative(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);
    final int diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return _weekdayDayMonth.format(date);
    return _dayMonthYear.format(date);
  }

  /// Returns the inclusive first/last day of the month containing [date].
  static (DateTime, DateTime) monthBounds(DateTime date) {
    final DateTime start = DateTime(date.year, date.month, 1);
    final DateTime end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return (start, end);
  }

  /// Returns the inclusive first/last day of the year containing [date].
  static (DateTime, DateTime) yearBounds(DateTime date) {
    final DateTime start = DateTime(date.year, 1, 1);
    final DateTime end = DateTime(date.year, 12, 31, 23, 59, 59);
    return (start, end);
  }
}
