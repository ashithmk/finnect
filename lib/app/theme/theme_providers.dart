import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Curated dual-color theme presets combining primary + accent gradient pairs.
enum AppThemePreset {
  authKitIndigoViolet, // #6967FB Royal Indigo + #9B51E0 Electric Violet
  cyberVoltEmerald, // #D5FF40 Cyber Lime + #10B981 Neon Emerald
  sapphireCyan, // #3B82F6 Sapphire Blue + #06B6D4 Cyan Glow
  midnightCrimson, // #185DF1 Midnight Blue + #EC4899 Crimson Pink
  sunsetAmber, // #F43F5E Sunset Rose + #F59E0B Amber Gold
}

extension AppThemePresetX on AppThemePreset {
  String get displayName {
    switch (this) {
      case AppThemePreset.authKitIndigoViolet:
        return 'Indigo & Violet Glow';
      case AppThemePreset.cyberVoltEmerald:
        return 'Cyber Volt & Emerald';
      case AppThemePreset.sapphireCyan:
        return 'Sapphire & Cyan Spark';
      case AppThemePreset.midnightCrimson:
        return 'Midnight & Crimson Pulse';
      case AppThemePreset.sunsetAmber:
        return 'Sunset & Amber Gold';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemePreset.authKitIndigoViolet:
        return const Color(0xFF6967FB);
      case AppThemePreset.cyberVoltEmerald:
        return const Color(0xFFD5FF40);
      case AppThemePreset.sapphireCyan:
        return const Color(0xFF3B82F6);
      case AppThemePreset.midnightCrimson:
        return const Color(0xFF185DF1);
      case AppThemePreset.sunsetAmber:
        return const Color(0xFFF43F5E);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AppThemePreset.authKitIndigoViolet:
        return const Color(0xFF9B51E0);
      case AppThemePreset.cyberVoltEmerald:
        return const Color(0xFF10B981);
      case AppThemePreset.sapphireCyan:
        return const Color(0xFF06B6D4);
      case AppThemePreset.midnightCrimson:
        return const Color(0xFFEC4899);
      case AppThemePreset.sunsetAmber:
        return const Color(0xFFF59E0B);
    }
  }

  Color get buttonTextColor {
    switch (this) {
      case AppThemePreset.cyberVoltEmerald:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  LinearGradient get primaryGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );
  }
}

class ThemePresetNotifier extends Notifier<AppThemePreset> {
  @override
  AppThemePreset build() {
    return AppThemePreset.authKitIndigoViolet;
  }

  void setPreset(AppThemePreset preset) {
    state = preset;
  }
}

final themePresetProvider =
    NotifierProvider<ThemePresetNotifier, AppThemePreset>(
        ThemePresetNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = ThemeMode.light;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
