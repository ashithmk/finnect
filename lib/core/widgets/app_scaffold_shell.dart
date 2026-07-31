import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/constants/app_strings.dart';
import '../../app/utils/extensions.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'finnect_3d_background.dart';

/// The persistent bottom-navigation shell wrapped with Finnect 3D background.
class AppScaffoldShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffoldShell({super.key, required this.navigationShell});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: AppStrings.navDashboard),
    _NavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Friends',
    ),
    _NavItem(
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
      label: AppStrings.navAnalytics,
    ),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: AppStrings.navProfile),
  ];

  void _onTap(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: isKeyboardOpen
            ? null
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showAddTransactionSheet(context),
                  elevation: 6,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(Icons.add, size: 28, color: theme.colorScheme.onPrimary),
                ),
              ),
        bottomNavigationBar: BottomAppBar(
          color: isDark
              ? const Color(0xFF0F111C).withValues(alpha: 0.92)
              : theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: AppSizes.sm,
          padding: EdgeInsets.zero,
          height: AppSizes.bottomNavHeight,
          child: Row(
            children: [
              // Left tabs: Home (0) and Friends (1)
              Expanded(child: _buildTabItem(context, 0)),
              Expanded(child: _buildTabItem(context, 1)),

              // Empty spacer for the center FAB notch
              const SizedBox(width: 48),

              // Right tabs: Analytics (2) and Profile (3)
              Expanded(child: _buildTabItem(context, 2)),
              Expanded(child: _buildTabItem(context, 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int branchIndex) {
    final bool selected = navigationShell.currentIndex == branchIndex;
    final _NavItem item = _items[branchIndex];
    final ColorScheme scheme = context.colors;

    return InkWell(
      onTap: () => _onTap(branchIndex),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: AppSizes.iconMd,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: context.textStyles.labelSmall?.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
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
