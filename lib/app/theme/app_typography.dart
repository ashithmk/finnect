import 'package:flutter/material.dart';

/// Typography scale built on Material 3's [TextTheme].
///
/// Uses the platform default font family for now; swap [fontFamily] to a
/// custom font (e.g. "Inter") once assets are added in `pubspec.yaml`.
abstract class AppTypography {
  AppTypography._();

  static const String? fontFamily = null; // e.g. 'Inter' once bundled

  static TextTheme textTheme(Brightness brightness) {
    final Color base =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B);

    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 57, fontWeight: FontWeight.w400, color: base, height: 1.12),
      displayMedium: TextStyle(
          fontSize: 45, fontWeight: FontWeight.w400, color: base, height: 1.15),
      displaySmall: TextStyle(
          fontSize: 36, fontWeight: FontWeight.w400, color: base, height: 1.2),
      headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w600, color: base, height: 1.2),
      headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w600, color: base, height: 1.25),
      headlineSmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: base, height: 1.3),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: base, height: 1.3),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: base, height: 1.4),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: base, height: 1.4),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: base, height: 1.5),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, color: base, height: 1.45),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, color: base, height: 1.4),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: base, height: 1.3),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: base, height: 1.3),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: base, height: 1.3),
    ).apply(fontFamily: fontFamily);
  }

  /// Tabular-figure style for money amounts — keeps digits aligned in lists.
  static TextStyle amountStyle(BuildContext context,
      {required Color color, double fontSize = 16, FontWeight weight = FontWeight.w700}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.2,
    );
  }
}
