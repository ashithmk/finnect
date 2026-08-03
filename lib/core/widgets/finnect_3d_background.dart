import 'package:flutter/material.dart';

/// Deep Midnight Navy & Sapphire Blue ambient gradient background (#031130, #185df1, #f3f7fe).
class Finnect3DBackground extends StatelessWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Container(
        color: const Color(0xFFF3F7FE),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -80,
              width: 380,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF185DF1).withValues(alpha: 0.18),
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
        // Base Color Combo Gradient (#031130 to #0B1F4D)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF031130), // Deep Midnight Navy Top
                Color(0xFF0A1C44), // Mid Navy
                Color(0xFF020B20), // Dark Navy Bottom
              ],
            ),
          ),
        ),

        // Primary Ambient Sapphire Blue Radial Glow (#185DF1)
        Positioned(
          top: -110,
          right: -80,
          width: 440,
          height: 440,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF185DF1).withValues(alpha: 0.38),
                  const Color(0xFF185DF1).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // Secondary Frosted Ice Highlight Aura (#F3F7FE)
        Positioned(
          top: 200,
          left: -120,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF3F7FE).withValues(alpha: 0.12),
                  const Color(0xFF185DF1).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Tertiary Bottom-Right Sapphire Ambient Glow
        Positioned(
          bottom: -90,
          right: -70,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF185DF1).withValues(alpha: 0.25),
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
