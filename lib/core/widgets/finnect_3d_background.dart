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
        // Primary Radial Glow Aura (Finnect Center Glow)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.25),
                radius: 1.2,
                colors: [
                  const Color(0xFF1E284C).withValues(alpha: 0.70), // Inner indigo aura
                  const Color(0xFF141933).withValues(alpha: 0.50), // Mid ambient
                  const Color(0xFF090A0E).withValues(alpha: 0.95), // Deep edge
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Secondary Ambient Top-Right Accent Aura (Violet)
        Positioned(
          top: -100,
          right: -100,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7E57C2).withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Tertiary Bottom-Left Accent Aura (Cyan)
        Positioned(
          bottom: -90,
          left: -90,
          width: 320,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.20),
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
