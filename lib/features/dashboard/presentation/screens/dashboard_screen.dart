import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../widgets/balance_details_sheet.dart';
import '../widgets/reminder_sheet.dart';

/// Dashboard matching Google Stitch design system:
/// - Clean light mode white liquid glass hero & activity cards over multi-glow mesh backdrop
/// - Playfair Display headers & Inter body text
/// - Dark Charcoal "Add Funds" pill button in balance card header
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openSetReminderSheet(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const SetReminderSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = CurrencyFormatter();
    final summary = ref.watch(dashboardSummaryProvider);

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finnect',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () => _openSetReminderSheet(context, ref),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _TotalBalanceCard(
                currency: currency,
                totalBalance: summary.totalBalance,
                savings: summary.savings,
              ),
              const SizedBox(height: 16),

              _MonthlyExpenseCard(
                currency: currency,
                monthlyExpense: summary.monthlyExpense,
              ),
              const SizedBox(height: 24),

              _SectionHeader(
                title: 'Recent Activity',
                onSeeAll: () => context.go(RouteNames.transactions),
              ),
              const SizedBox(height: 12),

              _RecentTransactionsList(
                transactions: summary.recentTransactions,
                currency: currency,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalBalanceCard extends ConsumerWidget {
  final CurrencyFormatter currency;
  final double totalBalance;
  final double savings;

  const _TotalBalanceCard({
    required this.currency,
    required this.totalBalance,
    required this.savings,
  });

  void _openAddBalance(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const AddTransactionSheet(
        initialType: TransactionType.income,
        lockType: true,
      ),
    );
  }

  void _openBalanceDetails(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const BalanceDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeBalance = totalBalance.isNaN ? 0.0 : totalBalance;
    final safeSavings = (savings.isNaN || savings < 0) ? 0.0 : savings;

    return FinnectGlassCard(
      onTap: () => _openBalanceDetails(context, ref),
      blur: 20,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(safeBalance),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9999),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: () => _openAddBalance(context, ref),
                  borderRadius: BorderRadius.circular(9999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Funds',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings: ${currency.format(safeSavings)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyExpenseCard extends StatelessWidget {
  final CurrencyFormatter currency;
  final double monthlyExpense;

  const _MonthlyExpenseCard({
    required this.currency,
    required this.monthlyExpense,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final safeExpense =
        (monthlyExpense.isNaN || monthlyExpense < 0) ? 0.0 : monthlyExpense;

    return FinnectGlassCard(
      blur: 20,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.expense.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.expense,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses ($monthName)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currency.format(safeExpense),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentTransactionsList extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final CurrencyFormatter currency;

  const _RecentTransactionsList({
    required this.transactions,
    required this.currency,
  });

  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> txList) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();

    for (final tx in txList) {
      final date = tx.date;
      String groupKey;

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groupKey = 'Today';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        groupKey = 'Yesterday';
      } else {
        groupKey = DateFormat.yMMMMd().format(date);
      }

      grouped.putIfAbsent(groupKey, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return FinnectGlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions in the past 7 days',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showAppModalBottomSheet(
                  context: context,
                  ref: ref,
                  builder: (ctx) => const AddTransactionSheet(
                    initialType: TransactionType.expense,
                    lockType: true,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupTransactions(transactions);
    final groupKeys = grouped.keys.toList();

    return Column(
      children: [
        for (final groupKey in groupKeys)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecentDayCard(
              groupKey: groupKey,
              items: grouped[groupKey] ?? [],
              currency: currency,
            ),
          ),
      ],
    );
  }
}

class _RecentDayCard extends StatefulWidget {
  final String groupKey;
  final List<TransactionModel> items;
  final CurrencyFormatter currency;

  const _RecentDayCard({
    required this.groupKey,
    required this.items,
    required this.currency,
  });

  @override
  State<_RecentDayCard> createState() => _RecentDayCardState();
}

class _RecentDayCardState extends State<_RecentDayCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.groupKey == 'Today';
  }

  @override
  Widget build(BuildContext context) {
    double dayIncome = 0.0;
    double dayExpense = 0.0;
    for (final item in widget.items) {
      if (item.type == TransactionType.income) {
        dayIncome += item.amount;
      } else {
        dayExpense += item.amount;
      }
    }
    if (dayIncome.isNaN) dayIncome = 0.0;
    if (dayExpense.isNaN) dayExpense = 0.0;

    final String? subtitleText =
        dayIncome > 0 ? '+${widget.currency.format(dayIncome)}' : null;

    final rightSideAmountStr = dayExpense > 0
        ? '-${widget.currency.format(dayExpense)}'
        : (dayIncome > 0
            ? '+${widget.currency.format(dayIncome)}'
            : widget.currency.format(0.0));

    final rightSideColor = dayExpense > 0
        ? AppColors.textPrimary
        : (dayIncome > 0 ? AppColors.income : AppColors.textSecondary);

    return FinnectGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassSubtleFill,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupKey,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitleText != null)
                          Text(
                            subtitleText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.income,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rightSideAmountStr,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: rightSideColor,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++)
                    _TransactionTile(
                      transaction: widget.items[i],
                      currency: widget.currency,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final CurrencyFormatter currency;

  const _TransactionTile({
    required this.transaction,
    required this.currency,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
            'Are you sure you want to delete "${transaction.title}"? Your total balance will be recalculated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(transactionControllerProvider.notifier)
                  .deleteTransaction(transaction.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${transaction.title} deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('grocer') || lower.contains('shop') || lower.contains('food')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('cafe') || lower.contains('din') || lower.contains('restau')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('salary') || lower.contains('income') || lower.contains('deposit')) {
      return Icons.account_balance_outlined;
    }
    if (lower.contains('car') || lower.contains('uber') || lower.contains('transp')) {
      return Icons.directions_car_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final timeStr = DateFormat.jm().format(transaction.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(transaction.category),
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.category} · $timeStr',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? "+" : "-"}${currency.format(transaction.amount.abs())}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.income : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
