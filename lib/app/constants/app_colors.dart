import 'package:flutter/material.dart';

/// Centralized color palette for the Finnect app.
abstract class AppColors {
  AppColors._();

  // Brand seed colors (Original Finnect Indigo / Blue)
  static const Color seedLight = Color(0xFF2E7D32);
  static const Color seedDark = Color(0xFF3F51B5);

  // Finnect 3D Aura Gradient Colors (Original Palette)
  static const Color finnectIndigo = Color(0xFF3F51B5);
  static const Color finnectBlue = Color(0xFF1E88E5);
  static const Color finnectViolet = Color(0xFF7E57C2);
  static const Color finnectCyan = Color(0xFF00BCD4);
  static const Color finnectAuraCenter = Color(0xFF1A2142);

  // Deprecated Aliases for backward compatibility
  static const Color geminiIndigo = finnectIndigo;
  static const Color geminiBlue = finnectBlue;
  static const Color geminiViolet = finnectViolet;
  static const Color geminiCyan = finnectCyan;
  static const Color geminiAuraCenter = finnectAuraCenter;

  // Semantic — financial meaning
  static const Color income = Color(0xFF4CAF50); // green
  static const Color expense = Color(0xFFFF5252); // red
  static const Color transfer = Color(0xFF29B6F6); // blue
  static const Color neutral = Color(0xFF9E9E9E); // grey

  // Budget progress thresholds
  static const Color budgetSafe = Color(0xFF66BB6A); // < 80%
  static const Color budgetWarning = Color(0xFFFFB74D); // 80–100%
  static const Color budgetDanger = Color(0xFFFF5252); // > 100%

  // Surfaces (Deep Finnect Dark + Glass Finish)
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF090A0E); // Deep Cosmic Dark
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF141622); // Translucent 3D Glass

  // Default category palette
  static const List<Color> categoryPalette = <Color>[
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF29B6F6),
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
