import 'package:flutter/material.dart';

/// 1:1 Implementation of the ambient mesh background from the mockup image:
/// - Silvery mist base: #F4F5F7
/// - Top-Left Periwinkle Glow: rgba(214, 224, 240, 0.65)
/// - Bottom-Right Mist Teal Glow: rgba(216, 232, 230, 0.45)
/// - Top-Right Pearl Lavender Glow: rgba(235, 230, 242, 0.45)
class Finnect3DBackground extends StatelessWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Container(
        color: const Color(0xFFF4F5F7),
        child: Stack(
          children: [
            // 1. Top-Left Soft Periwinkle Glow
            Positioned(
              top: -80,
              left: -60,
              width: 480,
              height: 480,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, -0.5),
                    radius: 0.85,
                    colors: [
                      const Color(0xFFD6E0F0).withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 2. Bottom-Right Soft Mist Teal Glow
            Positioned(
              bottom: -100,
              right: -80,
              width: 520,
              height: 520,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.5, 0.5),
                    radius: 0.85,
                    colors: [
                      const Color(0xFFD8E8E6).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Top-Right Soft Pearl Lavender Glow
            Positioned(
              top: -100,
              right: -60,
              width: 450,
              height: 450,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.6),
                    radius: 0.85,
                    colors: [
                      const Color(0xFFEBE6F2).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Screen Content
            child,
          ],
        ),
      );
    }

    // Dark Mode Fallback
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            width: 440,
            height: 440,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4648D4).withValues(alpha: 0.18),
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
}
