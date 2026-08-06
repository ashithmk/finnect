import 'dart:ui';
import 'package:flutter/material.dart';

/// 1:1 Match of Liquid Glass White Bento Cards from reference mockup image:
/// - Pure crisp white card container: #FFFFFF (with 90-95% translucency)
/// - Corner Radius: 28px - 32px
/// - Backdrop Filter Blur: 20px
/// - Border: 1px solid rgba(255, 255, 255, 0.90) / rgba(0, 0, 0, 0.04)
/// - Soft 3D Drop Shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.06) + inset specular glow
class StitchGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glassColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool isDarkGlass;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const StitchGlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.padding = const EdgeInsets.all(24.0),
    this.margin,
    this.glassColor,
    this.borderColor,
    this.gradient,
    this.isDarkGlass = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark || isDarkGlass;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(28.0);

    final defaultGlassColor = isDark
        ? const Color(0xFF252830).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.92);

    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white;

    Widget body = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (glassColor ?? defaultGlassColor) : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: borderColor ?? defaultBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white,
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: body,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: body,
        ),
      ),
    );
  }
}
