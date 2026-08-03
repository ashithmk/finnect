import 'package:flutter/material.dart';

/// Centralized color palette for the Finnect app.
/// Uses requested color combo:
/// - Hex: #031130 (Deep Midnight Navy)
/// - Hex: #185DF1 (Vibrant Sapphire Blue)
/// - Hex: #F3F7FE (Frosted Ice Highlight)
abstract class AppColors {
  AppColors._();

  // Primary Theme Hex Colors requested by user
  static const Color navyDark = Color(0xFF031130);
  static const Color electricBlue = Color(0xFF185DF1);
  static const Color iceHighlight = Color(0xFFF3F7FE);

  // Brand seed colors
  static const Color seedLight = Color(0xFF185DF1);
  static const Color seedDark = Color(0xFF185DF1);

  // Finnect Gradient Colors
  static const Color finnectNavy = Color(0xFF031130);
  static const Color finnectBlue = Color(0xFF185DF1);
  static const Color finnectIce = Color(0xFFF3F7FE);
  static const Color finnectCyan = Color(0xFF00E5FF);

  // Default Primary Theme Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF031130), // Deep Midnight Navy
      Color(0xFF185DF1), // Electric Sapphire Blue
    ],
  );

  // Accent Glass Gradient with Ice Highlight
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B1F4D),
      Color(0xFF185DF1),
    ],
  );

  // Semantic — financial meaning
  static const Color income = Color(0xFF00E676); // Vibrant Green
  static const Color expense = Color(0xFFFF5252); // Red
  static const Color transfer = Color(0xFF185DF1); // Sapphire Blue
  static const Color neutral = Color(0xFF90A4AE); // Grey

  // Budget progress thresholds
  static const Color budgetSafe = Color(0xFF00E676);
  static const Color budgetWarning = Color(0xFFFFB74D);
  static const Color budgetDanger = Color(0xFFFF5252);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF3F7FE); // Ice Light Surface
  static const Color surfaceDark = Color(0xFF031130); // Midnight Navy Dark Surface
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF0A1838); // Liquid Glass Card

  // Default category palette
  static const List<Color> categoryPalette = <Color>[
    Color(0xFF185DF1),
    Color(0xFF00E5FF),
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFF9CCC65),
    Color(0xFFFFCA28),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  static Color budgetColorForPercent(double budgetPercent) {
    if (budgetPercent >= 1.0) return budgetDanger;
    if (budgetPercent >= 0.8) return budgetWarning;
    return budgetSafe;
  }
}
