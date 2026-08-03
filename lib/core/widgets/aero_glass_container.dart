import 'dart:ui';
import 'package:flutter/material.dart';

/// Modern Pinterest-style Liquid Glassmorphism Container featuring:
/// - Deep slate frosted glass blur (`BackdropFilter` sigma 24)
/// - Delicate white specular border stroke (`Colors.white.withValues(alpha: 0.22)`)
/// - Deep volumetric soft glow shadow
/// - Sleek 24px - 32px rounded corners matching FitPulse UI mockups
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glassColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double borderWidth;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 22.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.glassColor,
    this.borderColor,
    this.gradient,
    this.borderWidth = 1.2,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(24.0);
    final defaultGlassColor = glassColor ??
        (isDark
            ? const Color(0xFF1A233A).withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.68));

    final defaultBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.65));

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? defaultGlassColor : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: defaultBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF090D1A).withValues(alpha: 0.50)
                : const Color(0xFF3F51B5).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for LiquidGlassContainer
typedef AeroGlassContainer = LiquidGlassContainer;
