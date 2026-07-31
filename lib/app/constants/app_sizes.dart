/// Centralized spacing, radius, and sizing constants.
///
/// Using a fixed spacing scale keeps the UI visually consistent across
/// every feature module. Always prefer these constants over magic numbers.
abstract class AppSizes {
  AppSizes._();

  // Spacing scale (4pt grid)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Border radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  // Component sizing
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 72;

  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double bottomNavHeight = 64;
  static const double fabSize = 64;

  static const double cardElevation = 0; // Material 3 favors tonal surfaces
  static const double maxContentWidth = 640; // tablet/desktop constraint
}
