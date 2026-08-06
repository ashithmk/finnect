import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

/// Finnect Liquid Glass Card — core glass-morphism container used across
/// all Finnect bento-layout screens.
/// - Pure white card container (#FFFFFF, 92% translucency)
/// - Corner Radius: 28px default
/// - Backdrop Filter Blur: 20px
/// - Border: 1px solid #FFFFFF specular highlight
/// - Soft 3D Drop Shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.06) + inset specular glow
class FinnectGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glassColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const FinnectGlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.padding = const EdgeInsets.all(24.0),
    this.margin,
    this.glassColor,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(28.0);

    final defaultGlassColor = Colors.white.withValues(alpha: 0.92);
    final defaultBorderColor = AppColors.glassBorder;

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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 2,
            spreadRadius: 0,
            offset: Offset(0, 1),
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
