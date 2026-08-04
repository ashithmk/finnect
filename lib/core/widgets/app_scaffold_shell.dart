import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/constants/app_strings.dart';
import '../../app/utils/extensions.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../providers/ui_providers.dart';
import 'finnect_3d_background.dart';

/// Floating 3D Aero Glass Capsule Navigation Bar matching modern pill UI mockups.
class AppScaffoldShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffoldShell({super.key, required this.navigationShell});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, selectedIcon: Icons.home_rounded, label: AppStrings.navDashboard),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      selectedIcon: Icons.receipt_long_rounded,
      label: AppStrings.navTransactions,
    ),
    _NavItem(
      icon: Icons.pie_chart_rounded,
      selectedIcon: Icons.pie_chart_rounded,
      label: AppStrings.navAnalytics,
    ),
    _NavItem(icon: Icons.person_rounded, selectedIcon: Icons.person_rounded, label: AppStrings.navProfile),
  ];

  void _onTap(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _showAddTransactionSheet(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const AddTransactionSheet(
        initialType: TransactionType.expense,
        lockType: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isSheetOpen = ref.watch(isBottomSheetOpenProvider);
    final mediaQuery = MediaQuery.of(context);

    final glassGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF23283B).withValues(alpha: 0.85),
              const Color(0xFF0E1322).withValues(alpha: 0.90),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.90),
              const Color(0xFFEBF1FA).withValues(alpha: 0.85),
            ],
          );

    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.75);

    final bottomPadding = mediaQuery.padding.bottom > 0
        ? mediaQuery.padding.bottom + 8.0
        : 16.0;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Fullscreen Screen Body extending 100% to bottom edge
            Positioned.fill(
              child: navigationShell,
            ),

            // 2. Floating 3D Capsule Navigation Bar floating directly over 3D background
            // Hidden completely whenever keyboard is open OR any modal bottom sheet is open.
            if (!isKeyboardOpen && !isSheetOpen)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: bottomPadding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: glassGradient,
                        borderRadius: BorderRadius.circular(36.0),
                        border: Border.all(
                          color: glassBorderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.50)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _buildTabItem(context, 0)),
                          Expanded(child: _buildTabItem(context, 1)),
                          _buildCenterAddButton(context, ref),
                          Expanded(child: _buildTabItem(context, 2)),
                          Expanded(child: _buildTabItem(context, 3)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.50),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => _showAddTransactionSheet(context, ref),
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 26,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int branchIndex) {
    final bool selected = navigationShell.currentIndex == branchIndex;
    final _NavItem item = _items[branchIndex];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = selected
        ? const Color(0xFF6967FB)
        : (isDark ? const Color(0xFF64748B) : theme.colorScheme.onSurfaceVariant);

    return InkWell(
      onTap: () => _onTap(branchIndex),
      borderRadius: BorderRadius.circular(24),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: activeColor,
                  size: 22,
                  shadows: selected
                      ? [
                          Shadow(
                            color: activeColor.withValues(alpha: 0.60),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  shadows: selected
                      ? [
                          Shadow(
                            color: activeColor.withValues(alpha: 0.40),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
