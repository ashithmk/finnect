import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/constants/app_strings.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../providers/ui_providers.dart';
import 'finnect_3d_background.dart';

/// Floating capsule navigation bar 1:1 matching the reference mockup image:
/// - Full rounded pill capsule: borderRadius 9999
/// - Background: rgba(255, 255, 255, 0.92) with 20px blur & 1px white border
/// - Active Tab: Solid dark charcoal capsule (#1A1C23 / #000000) with white icon and text label
/// - Inactive Tabs: Subtle circular icon buttons
class AppScaffoldShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffoldShell({super.key, required this.navigationShell});

  static const List<_NavItem> _items = [
    _NavItem(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
        label: AppStrings.navDashboard),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: AppStrings.navTransactions,
    ),
    _NavItem(
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.insights_rounded,
      label: 'Stats',
    ),
    _NavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: AppStrings.navProfile),
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
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

    final bottomPadding =
        mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom + 12.0 : 20.0;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Fullscreen Body
            Positioned.fill(
              child: navigationShell,
            ),

            // 2. Floating Capsule Navigation Bar matching mockup
            if (!isKeyboardOpen && !isSheetOpen)
              Positioned(
                left: 20.0,
                right: 20.0,
                bottom: bottomPadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF252830).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 35,
                                spreadRadius: 0,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTabItem(context, 0),
                              _buildTabItem(context, 1),
                              _buildCenterAddButton(context, ref),
                              _buildTabItem(context, 2),
                              _buildTabItem(context, 3),
                            ],
                          ),
                        ),
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
    return InkWell(
      onTap: () => _showAddTransactionSheet(context, ref),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1C23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int branchIndex) {
    final bool selected = navigationShell.currentIndex == branchIndex;
    final _NavItem item = _items[branchIndex];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (selected) {
      return InkWell(
        onTap: () => _onTap(branchIndex),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : const Color(0xFF1A1C23),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.selectedIcon,
                color: isDark ? const Color(0xFF1A1C23) : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF1A1C23) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _onTap(branchIndex),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          item.icon,
          color: isDark ? Colors.white54 : const Color(0xFF757885),
          size: 22,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(
      {required this.icon, required this.selectedIcon, required this.label});
}
