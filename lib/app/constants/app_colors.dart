import 'package:flutter/material.dart';

/// Pure 1:1 color palette derived strictly from Google Stitch Liquid Minimalist light design:
/// - Primary Charcoal & Text: #1A1C23
/// - Pure White Card Fill: #FFFFFF
/// - Ambient Canvas Atmosphere: #F4F5F7 (Silvery Mist)
/// - Slate Dark Accent Banner: #252830
/// - Muted Secondary Text: #757885
/// - Positive Cash Flow / Income: #005236
/// - Expense / Negative: #BA1A1A
abstract class AppColors {
  AppColors._();

  // Core Stitch Light Palette
  static const Color primary = Color(0xFF1A1C23);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF252830);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF4648D4);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6063EE);

  static const Color surface = Color(0xFFF4F5F7);
  static const Color surfaceLight = Color(0xFFF4F5F7);
  static const Color cardLight = Colors.white;

  static const Color textPrimary = Color(0xFF1A1C23);
  static const Color textSecondary = Color(0xFF757885);
  static const Color textMuted = Color(0xFFA0A3AF);

  static const Color onSurface = Color(0xFF1A1C23);
  static const Color onSurfaceVariant = Color(0xFF757885);
  static const Color outline = Color(0xFFE2E4E8);
  static const Color outlineVariant = Color(0xFFECEEEF);

  // Glass Container Fill & Border Specifications
  static const Color glassCardFill = Colors.white; // Pure White Card Fill
  static const Color glassCardBorder = Color(0xFFFFFFFF); // Specular Highlight Border
  static const Color glassNavFill = Color(0xF2FFFFFF); // rgba(255, 255, 255, 0.95)
  static const Color glassSubtleFill = Color(0xFFF6F7F9); // Stat Pill Fill

  // Financial Semantics
  static const Color income = Color(0xFF005236);
  static const Color expense = Color(0xFFBA1A1A);
  static const Color transfer = Color(0xFF4648D4);
  static const Color neutral = Color(0xFF757885);

  static const Color budgetSafe = Color(0xFF005236);
  static const Color budgetWarning = Color(0xFFF59E0B);
  static const Color budgetDanger = Color(0xFFBA1A1A);

  // Design Tokens & Aliases
  static const Color primaryIndigo = Color(0xFF1A1C23);
  static const Color deepIndigo = Color(0xFF252830);
  static const Color softIndigo = Color(0xFF4648D4);
  static const Color glassBorder = Color(0xFFFFFFFF);
  static const Color iceWhite = Color(0xFFFFFFFF);
  static const Color mutedPeriwinkle = Color(0xFF757885);
  static const Color seedLight = Color(0xFF1A1C23);

  static const List<Color> categoryPalette = <Color>[
    Color(0xFF1A1C23),
    Color(0xFF4648D4),
    Color(0xFF005236),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF757885),
  ];

  static Color budgetColorForPercent(double budgetPercent) {
    if (budgetPercent >= 1.0) return budgetDanger;
    if (budgetPercent >= 0.8) return budgetWarning;
    return budgetSafe;
  }
}
