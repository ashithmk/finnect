import 'package:flutter/material.dart';

/// Centralized color palette for Finnect centered around signature #6967FB Royal Indigo Blue:
/// - Hex: #6967FB (Primary Royal Indigo Blue Accent)
/// - Hex: #504DE4 (Deep Indigo Blue Shadow)
/// - Hex: #8A88FF (Soft Electric Periwinkle Highlight)
/// - Hex: #090A10 (Deep Obsidian Black Base)
/// - Hex: #141926 (Translucent Glass Fill)
/// - Hex: #2A3650 (Specular Metallic Glass Border)
/// - Hex: #F1F5F9 (Crisp Ice White Text)
/// - Hex: #94A3B8 (Muted Periwinkle Slate)
abstract class AppColors {
  AppColors._();

  // Signature requested color #6967FB and complementary indigo-blue shades
  static const Color primaryIndigo = Color(0xFF6967FB);
  static const Color deepIndigo = Color(0xFF504DE4);
  static const Color softIndigo = Color(0xFF8A88FF);

  static const Color obsidianBlack = Color(0xFF090A10);
  static const Color midnightNavy = Color(0xFF0C0E17);
  static const Color glassCardFill = Color(0xFF141926);
  static const Color glassBorder = Color(0xFF2A3650);
  static const Color iceWhite = Color(0xFFF1F5F9);
  static const Color mutedPeriwinkle = Color(0xFF94A3B8);
  static const Color darkInputFill = Color(0xFF111624);

  // Brand seed colors
  static const Color seedLight = Color(0xFF6967FB);
  static const Color seedDark = Color(0xFF6967FB);

  // Signature #6967FB Radial Spotlight Gradient
  static const RadialGradient topSpotlightGradient = RadialGradient(
    center: Alignment(0.0, -1.2),
    radius: 1.4,
    colors: [
      Color(0x596967FB), // Soft #6967FB Beam Core
      Color(0x333A38A0), // Atmosphere Glow
      Colors.transparent,
    ],
    stops: [0.0, 0.45, 1.0],
  );

  // Primary #6967FB Button Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6967FB), // Royal Indigo #6967FB Top-Left
      Color(0xFF504DE4), // Deep Indigo #504DE4 Bottom-Right
    ],
  );

  // Active Accent Gradient
  static const LinearGradient activeAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6967FB),
      Color(0xFF8A88FF),
    ],
  );

  // AuthKit Frosted Glass Container Gradient
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF181F30),
      Color(0xFF0F1420),
    ],
  );

  // Total Balance Card Gradient
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2234),
      Color(0xFF101522),
      Color(0xFF090A10),
    ],
  );

  // Semantic — financial meaning
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFEF4444); // Crimson Red
  static const Color transfer = Color(0xFF6967FB); // #6967FB Indigo
  static const Color neutral = Color(0xFF94A3B8);

  // Budget progress thresholds
  static const Color budgetSafe = Color(0xFF10B981);
  static const Color budgetWarning = Color(0xFFF59E0B);
  static const Color budgetDanger = Color(0xFFEF4444);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF090A10);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF141926);

  // Default category palette
  static const List<Color> categoryPalette = <Color>[
    Color(0xFF6967FB),
    Color(0xFF8A88FF),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
  ];

  static Color budgetColorForPercent(double budgetPercent) {
    if (budgetPercent >= 1.0) return budgetDanger;
    if (budgetPercent >= 0.8) return budgetWarning;
    return budgetSafe;
  }
}
