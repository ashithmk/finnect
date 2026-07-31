import 'package:flutter/material.dart';

/// Extension methods on BuildContext for quick access to Theme, MediaQuery, etc.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

/// Handy DateTime helpers used throughout transactions/calendar/budget.
extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) => year == other.year && month == other.month;

  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);
}

/// Number helpers for percentage/clamping used in budget progress bars.
extension NumX on num {
  double clampedPercentOf(num total) {
    if (total <= 0) return 0.0;
    return (this / total).clamp(0.0, 1.5).toDouble();
  }
}

/// String helpers.
extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isNullOrEmptyTrimmed => trim().isEmpty;
}
