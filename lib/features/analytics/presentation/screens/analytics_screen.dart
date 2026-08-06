import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';

enum AnalyticsPeriod { week, month, year, lastYear }

/// Redesigned Analytics Screen: Insight first, then Top Categories. No bar chart.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('grocer') || lower.contains('shop') || lower.contains('accessories')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('food') || lower.contains('din') || lower.contains('cafe')) {
      return Icons.restaurant_outlined;
    }
    if (lower.contains('petrol') || lower.contains('fuel') || lower.contains('transp')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('lend')) {
      return Icons.handshake_outlined;
    }
    return Icons.category_outlined;
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

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: transactionsAsync.when(
            data: (allTransactions) {
              final expenses = _filterExpensesByPeriod(allTransactions);

              if (expenses.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    EmptyState(
                      icon: Icons.insights_rounded,
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
                  ],
                );
              }

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
              final topCategoryName = topCategory?.key ?? 'Dining';
              final topCategoryAmount = topCategory?.value ?? 0.0;
              final topPercentage = (totalExpense > 0 && topCategoryAmount > 0)
                  ? (topCategoryAmount / totalExpense * 100).toStringAsFixed(0)
                  : '0';

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // Main Spending Hero Card (no chart)
                  _SpendingHeroCard(
                    totalExpense: totalExpense,
                    currency: currency,
                    periodLabel: _getPeriodLabel(_selectedPeriod),
                  ),
                  const SizedBox(height: 16),

                  // Quick Insights Card — shown ABOVE top categories
                  _QuickInsightsCard(
                    topCategoryName: topCategoryName,
                    topCategoryAmount: topCategoryAmount,
                    topPercentage: topPercentage,
                    currency: currency,
                    periodLabel: _getPeriodLabel(_selectedPeriod),
                  ),
                  const SizedBox(height: 16),

                  // Top Categories heading
                  Text(
                    'Top Categories',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Top Category Glass Tiles List
                  FinnectGlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        for (int i = 0; i < sortedCategories.length; i++) ...[
                          _CategoryBentoTile(
                            categoryName: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            percentage: totalExpense > 0
                                ? (sortedCategories[i].value / totalExpense * 100)
                                    .toStringAsFixed(0)
                                : '0',
                            icon: _getCategoryIcon(sortedCategories[i].key),
                            currency: currency,
                          ),
                          if (i < sortedCategories.length - 1)
                            const Divider(height: 12, indent: 64),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoader(),
            error: (err, stack) => Center(
              child: Text('Error loading analytics: $err'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Analytics',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AnalyticsPeriod>(
                  value: _selectedPeriod,
                  isDense: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      size: 18, color: AppColors.textPrimary),
                  dropdownColor: AppColors.surface,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  items: AnalyticsPeriod.values.map((p) {
                    return DropdownMenuItem<AnalyticsPeriod>(
                      value: p,
                      child: Text(_getPeriodLabel(p).toUpperCase()),
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
      ],
    );
  }
}

/// Spending Hero Card — Total Spent with no chart
class _SpendingHeroCard extends StatelessWidget {
  final double totalExpense;
  final CurrencyFormatter currency;
  final String periodLabel;

  const _SpendingHeroCard({
    required this.totalExpense,
    required this.currency,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FinnectGlassCard(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currency.format(totalExpense),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total spent this $periodLabel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+12%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Category Bento Tile
class _CategoryBentoTile extends StatelessWidget {
  final String categoryName;
  final double amount;
  final String percentage;
  final IconData icon;
  final CurrencyFormatter currency;

  const _CategoryBentoTile({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
              ),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currency.format(amount),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

/// Dark Metallic Quick Insights Card — no "Review Budget" button
class _QuickInsightsCard extends StatelessWidget {
  final String topCategoryName;
  final double topCategoryAmount;
  final String topPercentage;
  final CurrencyFormatter currency;
  final String periodLabel;

  const _QuickInsightsCard({
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.topPercentage,
    required this.currency,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FinnectGlassCard(
      glassColor: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your spending on $topCategoryName is $topPercentage% of your total expenses in $periodLabel (${currency.format(topCategoryAmount)}).',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
