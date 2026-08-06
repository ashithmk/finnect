import 'package:flutter/material.dart';

/// 1:1 Implementation of the minimalist silvery grey mist background from the user screenshot:
/// - Silvery grey canvas base: #E4E7EC
/// - Top-Left Soft Metallic Mist: #BDC2CC fading softly
/// - Bottom-Right Soft Slate Glow: #C8CDD6 fading softly
/// - Center Soft Ambient Highlight: #F7F8FA for high contrast against crisp white cards
class Finnect3DBackground extends StatelessWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4E7EC),
      child: Stack(
        children: [
          // 1. Top-Left Soft Silvery Metallic Mist
          Positioned(
            top: -140,
            left: -120,
            width: 580,
            height: 580,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.4),
                  radius: 0.85,
                  colors: [
                    const Color(0xFFBAC0CB).withValues(alpha: 0.75),
                    const Color(0xFFE4E7EC).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Bottom-Right Soft Slate Mist Curve
          Positioned(
            bottom: -160,
            right: -140,
            width: 620,
            height: 620,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.4, 0.4),
                  radius: 0.85,
                  colors: [
                    const Color(0xFFC2C7D2).withValues(alpha: 0.70),
                    const Color(0xFFE4E7EC).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Center Soft Off-White Ambient Light
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFF4F5F7).withValues(alpha: 0.40),
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
}
