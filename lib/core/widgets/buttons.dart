import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/constants/app_sizes.dart';

/// Primary Pinterest/AuthKit-style capsule pill button with signature #6967FB Indigo gradient,
/// specular border outline, and crisp white typography.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dual-Color Theme Preset Gradient
    final buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
      ],
    );

    final border = isDark
        ? Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.45),
            width: 1.2,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? buttonGradient : null,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: border,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.38),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: Container(
              height: AppSizes.buttonHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: AppSizes.sm),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: Icon(icon, size: 14, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary Liquid Glass pill button with frosted blur and specular stroke outline.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        color: isDark
            ? const Color(0xFF141926).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.70),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A3650).withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: Container(
                height: AppSizes.buttonHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      Icon(icon, size: AppSizes.iconSm, color: theme.colorScheme.onSurface),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Pinterest-style Liquid Glass filter chip button.
class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary
              : (isDark
                  ? const Color(0xFF141926).withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.60)),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.40)
                : const Color(0xFF2A3650).withValues(alpha: isDark ? 0.40 : 0.50),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: isSelected ? Colors.white : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : scheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
