import 'package:flutter/material.dart';

/// Deep oceanic ambient background supporting Pinterest-style Liquid Glassmorphism.
class Finnect3DBackground extends StatelessWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Container(
        color: const Color(0xFFEBF3FA),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -80,
              width: 350,
              height: 350,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E88E5).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Base Deep Oceanic Slate Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D1424), // Deep oceanic slate top
                Color(0xFF121B30), // Mid slate
                Color(0xFF090D18), // Deep slate bottom
              ],
            ),
          ),
        ),

        // Primary Ambient Top-Right Radial Glow Aura (Cyan/Blue Aura)
        Positioned(
          top: -120,
          right: -90,
          width: 420,
          height: 420,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00B4D8).withValues(alpha: 0.28),
                  const Color(0xFF1E88E5).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Secondary Mid Center-Left Accent Aura (Deep Violet Aura)
        Positioned(
          top: 220,
          left: -110,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7E57C2).withValues(alpha: 0.25),
                  const Color(0xFF3F51B5).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Tertiary Bottom-Right Ambient Aura (Electric Teal Glow)
        Positioned(
          bottom: -100,
          right: -80,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Main Content
        child,
      ],
    );
  }
}
