import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

/// Recreates the Finnect 3D cosmic background effect with stacked
/// radial gradients, ambient lighting auras, and subtle depth lighting.
class Finnect3DBackground extends StatelessWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return child;
    }

    return Stack(
      children: [
        // Base Deep Cosmic Background
        Container(
          color: AppColors.surfaceDark,
        ),
        // Primary Radial Glow Aura (Finnect Center Indigo Glow)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.25),
                radius: 1.3,
                colors: [
                  const Color(0xFF1E284C).withValues(alpha: 0.75), // Inner indigo glow
                  const Color(0xFF141933).withValues(alpha: 0.55), // Mid ambient
                  const Color(0xFF090A0E).withValues(alpha: 0.98), // Deep cosmic edge
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Secondary Ambient Top-Right Accent Aura (Violet Glow)
        Positioned(
          top: -110,
          right: -100,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7E57C2).withValues(alpha: 0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Tertiary Bottom-Left Accent Aura (Cyan Glow)
        Positioned(
          bottom: -100,
          left: -90,
          width: 350,
          height: 350,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main Screen Content
        child,
      ],
    );
  }
}
