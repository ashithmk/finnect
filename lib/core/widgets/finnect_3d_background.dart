import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_providers.dart';

/// WorkOS / AuthKit Signature Spotlight & Blueprint Grid ambient background
/// dynamically optimized for dual-color theme combinations and Light/Dark modes.
class Finnect3DBackground extends ConsumerWidget {
  final Widget child;

  const Finnect3DBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = ref.watch(themePresetProvider);

    if (!isDark) {
      // Normal Light Mode
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Stack(
          children: [
            // Top Right Soft Primary Ambient Spotlight
            Positioned(
              top: -120,
              right: -100,
              width: 420,
              height: 420,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      preset.primaryColor.withValues(alpha: 0.18),
                      preset.secondaryColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Left Soft Secondary Ambient Aura
            Positioned(
              bottom: -120,
              left: -100,
              width: 400,
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      preset.secondaryColor.withValues(alpha: 0.14),
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

    // Dark Mode with Dual-Color Gradient Spotlight & Blueprint Grid
    return Stack(
      children: [
        // 1. Base Midnight Obsidian Gradient (#090A10 to #06070B)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF090A10), // Deep Obsidian Base Top
                Color(0xFF0D101A), // Mid Midnight Slate
                Color(0xFF06070B), // Base Bottom
              ],
            ),
          ),
        ),

        // 2. Dual-Color Spotlight Beam (Primary Color to Secondary Accent)
        Positioned(
          top: -180,
          left: 0,
          right: 0,
          height: 600,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -1.0),
                radius: 1.3,
                colors: [
                  preset.primaryColor.withValues(alpha: 0.38),   // Primary Core
                  preset.secondaryColor.withValues(alpha: 0.20), // Secondary Dual Accent Glow
                  const Color(0xFF1E2842).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 0.75, 1.0],
              ),
            ),
          ),
        ),

        // 3. Subtle AuthKit Blueprint Grid Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AuthKitGridPainter(),
            ),
          ),
        ),

        // 4. Secondary Bottom Ambient Aura
        Positioned(
          bottom: -100,
          right: -80,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  preset.secondaryColor.withValues(alpha: 0.18),
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

/// Draws faint geometric grid lines matching the WorkOS / AuthKit preview mockup.
class _AuthKitGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A3650).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const double step = 64.0; // Grid line spacing

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
