import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Exact 1:1 Typography scale built on Material 3's [TextTheme] matching
/// Google Stitch specifications (`finnect_design/history_reverted_footer/code.html` lines 80-97):
/// - `display-balance`: Playfair Display 40px bold 700, -0.02em letter-spacing
/// - `headline-lg`: Playfair Display 32px semibold 600, -0.01em letter-spacing
/// - `headline-lg-mobile`: Playfair Display 28px semibold 600
/// - `headline-md`: Inter 18px semibold 600
/// - `body-lg`: Inter 16px medium 500
/// - `body-sm`: Inter 14px regular 400
/// - `label-caps`: Inter 12px bold 700 uppercase, 0.05em letter-spacing
abstract class AppTypography {
  AppTypography._();

  static String? fontFamily = GoogleFonts.inter().fontFamily;

  static TextTheme textTheme(Brightness brightness) {
    final Color base =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF191C1D);

    final interText = GoogleFonts.interTextTheme(
      TextTheme(
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: base,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: base,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: base,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.3,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: base,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: base,
          height: 1.3,
          letterSpacing: 0.6,
        ),
      ),
    );

    return interText.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: base,
        height: 1.2,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: base,
        height: 1.2,
        letterSpacing: -0.7,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: base,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: base,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: base,
        height: 1.3,
      ),
    );
  }

  /// Tabular-figure style for money amounts using Inter / Playfair
  static TextStyle amountStyle(
    BuildContext context, {
    required Color color,
    double fontSize = 18,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.3,
    );
  }
}
