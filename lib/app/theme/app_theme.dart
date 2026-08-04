import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_typography.dart';
import 'theme_providers.dart';

/// Builds the app's Light and Dark [ThemeData] dynamically configured by [AppThemePreset]:
/// WorkOS Indigo (#6967FB), Cyber Volt (#D5FF40), Sapphire Blue (#3B82F6), Midnight Navy (#185DF1).
abstract class AppTheme {
  AppTheme._();

  static ThemeData light({
    AppThemePreset preset = AppThemePreset.authKitIndigoViolet,
    ColorScheme? dynamicScheme,
  }) {
    final primary = preset.primaryColor;
    final secondary = preset.secondaryColor;
    final onPrimary = preset.buttonTextColor;

    final ColorScheme scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondary,
          onSecondary: Colors.white,
          surface: AppColors.surfaceLight,
          onSurface: Colors.black87,
          brightness: Brightness.light,
        );
    return _build(scheme, Brightness.light, preset);
  }

  static ThemeData dark({
    AppThemePreset preset = AppThemePreset.authKitIndigoViolet,
    ColorScheme? dynamicScheme,
  }) {
    final primary = preset.primaryColor;
    final secondary = preset.secondaryColor;
    final onPrimary = preset.buttonTextColor;

    final ColorScheme scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondary,
          onSecondary: Colors.white,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.iceWhite,
          onSurfaceVariant: AppColors.mutedPeriwinkle,
          brightness: Brightness.dark,
        );
    return _build(scheme, Brightness.dark, preset);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Brightness brightness,
    AppThemePreset preset,
  ) {
    final bool isDark = brightness == Brightness.dark;
    final TextTheme textTheme = AppTypography.textTheme(brightness);
    final primary = scheme.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.iceWhite : Colors.black87,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.iceWhite : Colors.black87,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark
            ? const Color(0xFF141926).withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.85),
        elevation: isDark ? 10 : 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(
            color: isDark
                ? AppColors.glassBorder.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.75),
            width: 1.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF111624).withValues(alpha: 0.85)
            : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF232C42).withValues(alpha: 0.60)
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF232C42).withValues(alpha: 0.60)
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(
            color: primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.mutedPeriwinkle : scheme.onSurfaceVariant,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF222C42) : primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            side: isDark
                ? const BorderSide(color: Color(0xFF38476B), width: 1.2)
                : BorderSide.none,
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.35),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          side: BorderSide(
            color: isDark ? AppColors.glassBorder : scheme.outline,
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF181F30)
            : scheme.surfaceContainerHighest,
        selectedColor: primary,
        secondaryLabelStyle: TextStyle(color: preset.buttonTextColor),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        side: BorderSide(
          color: isDark
              ? AppColors.glassBorder.withValues(alpha: 0.4)
              : BorderSide.none.color,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: preset.buttonTextColor,
        elevation: 6,
        shape: const CircleBorder(),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        indicatorColor: primary,
        height: AppSizes.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? primary : AppColors.mutedPeriwinkle,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : AppColors.mutedPeriwinkle,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: isDark
            ? AppColors.glassBorder.withValues(alpha: 0.40)
            : scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: isDark
            ? const Color(0xFF181F30)
            : scheme.surfaceContainerHighest,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1420) : AppColors.cardLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
        ),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }
}
