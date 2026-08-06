import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../../core/widgets/stitch_glass_card.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';

enum AnalyticsPeriod { week, month, year, lastYear }

/// Expenditure Behavior Analytics tab wrapped with Finnect 3D cosmic background.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'petrol':
        return Icons.local_gas_station;
      case 'accessories':
        return Icons.shopping_bag;
      case 'lend':
        return Icons.handshake_outlined;
      case 'split bill':
        return Icons.pie_chart;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'petrol':
        return Colors.redAccent;
      case 'accessories':
        return Colors.purpleAccent;
      case 'lend':
        return Colors.tealAccent;
      case 'split bill':
        return Colors.deepPurpleAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  List<TransactionModel> _filterExpensesByPeriod(
      List<TransactionModel> allTransactions) {
    final now = DateTime.now();
    return allTransactions.where((tx) {
      if (tx.type != TransactionType.expense) return false;

      switch (_selectedPeriod) {
        case AnalyticsPeriod.week:
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          return tx.date.isAfter(sevenDaysAgo);
        case AnalyticsPeriod.month:
          return tx.date.year == now.year && tx.date.month == now.month;
        case AnalyticsPeriod.year:
          return tx.date.year == now.year;
        case AnalyticsPeriod.lastYear:
          return tx.date.year == now.year - 1;
      }
    }).toList();
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.year:
        return 'Year';
      case AnalyticsPeriod.lastYear:
        return 'Last Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = CurrencyFormatter();
    final theme = Theme.of(context);

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.navAnalytics),
          actions: [
            // Top Right Corner History Button
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Transaction History',
              onPressed: () => context.push(RouteNames.transactions),
            ),
            const SizedBox(width: AppSizes.xs),
          ],
        ),
        body: transactionsAsync.when(
          data: (allTransactions) {
            final expenses = _filterExpensesByPeriod(allTransactions);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.sm,
                AppSizes.lg,
                AppSizes.xxl + AppSizes.xl,
              ),
              children: [
                // Top Left Corner Compact Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AnalyticsPeriod>(
                          value: _selectedPeriod,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              size: 16, color: Colors.white),
                          dropdownColor: theme.colorScheme.surface,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          items: AnalyticsPeriod.values.map((p) {
                            return DropdownMenuItem<AnalyticsPeriod>(
                              value: p,
                              child: Text(_getPeriodLabel(p)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPeriod = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                if (expenses.isEmpty) ...[
                  EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'No Data for ${_getPeriodLabel(_selectedPeriod)}',
                    subtitle:
                        'Tap the + button below to log your expenses and unlock spending insights for this period!',
                    actionLabel: 'Add Expense',
                    onAction: () {
                      showAppModalBottomSheet(
                        context: context,
                        ref: ref,
                        builder: (ctx) => const AddTransactionSheet(
                          initialType: TransactionType.expense,
                          lockType: true,
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Calculate total expense metrics
                  () {
                    double totalExpense = 0.0;
                    final Map<String, double> categorySums = {};

                    for (final tx in expenses) {
                      totalExpense += tx.amount;
                      categorySums[tx.category] =
                          (categorySums[tx.category] ?? 0.0) + tx.amount;
                    }

                    final sortedCategories = categorySums.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    final topCategory = sortedCategories.isEmpty
                        ? null
                        : sortedCategories.first;
                    final topCategoryName = topCategory?.key ?? 'None';
                    final topCategoryAmount = topCategory?.value ?? 0.0;
                    final topPercentage =
                        (totalExpense > 0 && topCategoryAmount > 0)
                            ? (topCategoryAmount / totalExpense * 100)
                                .toStringAsFixed(1)
                            : '0.0';
                    final avgExpense = expenses.isNotEmpty
                        ? totalExpense / expenses.length
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Behavior Highlight Card
                        _SpendingBehaviorCard(
                          topCategoryName: topCategoryName,
                          topCategoryAmount: topCategoryAmount,
                          topPercentage: topPercentage,
                          periodLabel: _getPeriodLabel(_selectedPeriod),
                          currency: currency,
                        ),
                        const SizedBox(height: AppSizes.md),

                        // Overview Metrics Row
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label:
                                    'Total Spent (${_getPeriodLabel(_selectedPeriod)})',
                                value: currency.formatCompact(totalExpense),
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: _MetricCard(
                                label: 'Avg per Expense',
                                value: currency.formatCompact(avgExpense),
                                icon: Icons.show_chart,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),

                        // Section Title
                        Text(
                          'Expenditure by Category (${_getPeriodLabel(_selectedPeriod)})',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),

                        // Category Breakdown List
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < sortedCategories.length;
                                    i++) ...[
                                  _CategoryProgressTile(
                                    categoryName: sortedCategories[i].key,
                                    amount: sortedCategories[i].value,
                                    percentage: totalExpense > 0
                                        ? (sortedCategories[i].value /
                                                totalExpense)
                                            .clamp(0.0, 1.0)
                                        : 0.0,
                                    icon: _getCategoryIcon(
                                        sortedCategories[i].key),
                                    color: _getCategoryColor(
                                        sortedCategories[i].key, context),
                                    currency: currency,
                                  ),
                                  if (i < sortedCategories.length - 1)
                                    const Divider(height: 24, indent: 48),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }(),
                ],
              ],
            );
          },
          loading: () => const AppLoader(),
          error: (err, stack) => Center(
            child: Text('Error loading analytics: $err'),
          ),
        ),
      ),
    );
  }
}

/// Highlight card analyzing user's top expenditure behavior.
class _SpendingBehaviorCard extends StatelessWidget {
  final String topCategoryName;
  final double topCategoryAmount;
  final String topPercentage;
  final String periodLabel;
  final CurrencyFormatter currency;

  const _SpendingBehaviorCard({
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.topPercentage,
    required this.periodLabel,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return StitchGlassCard(
      isDarkGlass: true,
      glassColor: const Color(0xFF0F172A).withValues(alpha: 0.80),
      borderColor: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insight',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your spending on $topCategoryName is higher in $periodLabel (${currency.format(topCategoryAmount)}), accounting for $topPercentage% of your total expenses.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text(
                'Review Budget',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSizes.iconSm, color: color),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  final String categoryName;
  final double amount;
  final double percentage; // 0.0 to 1.0
  final IconData icon;
  final Color color;
  final CurrencyFormatter currency;

  const _CategoryProgressTile({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pctString = (percentage * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currency.format(amount),
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$pctString% of total',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
