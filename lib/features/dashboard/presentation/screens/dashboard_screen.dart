import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../widgets/balance_details_sheet.dart';
import '../widgets/reminder_sheet.dart';

/// Dynamic Dashboard (Home) tab featuring Finnect 3D cosmic background,
/// Net Total Balance, Savings, Monthly Expenses, and 7-Day Recent History cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openSetReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
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
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Set Expense Reminder',
              onPressed: () => _openSetReminderSheet(context),
            ),
            const SizedBox(width: AppSizes.xs),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.xxl + AppSizes.xl),
            children: [
              _TotalBalanceCard(
                currency: currency,
                totalBalance: summary.totalBalance,
                savings: summary.savings,
              ),
              const SizedBox(height: AppSizes.md),
              _MonthlyExpenseCard(
                currency: currency,
                monthlyExpense: summary.monthlyExpense,
              ),
              const SizedBox(height: AppSizes.lg),
              _SectionHeader(
                title: 'Recent',
                onSeeAll: () => context.go(RouteNames.transactions),
              ),
              const SizedBox(height: AppSizes.sm),
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

/// Finnect 3D Total Balance card featuring signature blue-indigo-violet gradient,
/// Top-Left Add Balance button, and Bottom-Right Total Savings display.
/// Tapping the card opens the detailed BalanceDetailsSheet ("To Get" & "To Give").
class _TotalBalanceCard extends StatelessWidget {
  final CurrencyFormatter currency;
  final double totalBalance;
  final double savings;

  const _TotalBalanceCard({
    required this.currency,
    required this.totalBalance,
    required this.savings,
  });

  void _openAddBalance(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const AddTransactionSheet(
        initialType: TransactionType.income,
        lockType: true,
      ),
    );
  }

  void _openBalanceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const BalanceDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBalance = (totalBalance.isNaN || totalBalance < 0) ? 0.0 : totalBalance;
    final safeSavings = (savings.isNaN || savings < 0) ? 0.0 : savings;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBalanceDetails(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5), // Finnect Blue
                Color(0xFF3F51B5), // Finnect Indigo
                Color(0xFF7E57C2), // Finnect Violet
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with Top-Left "Add Balance" button
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _openAddBalance(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Add Balance',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Balance amount on left & Bottom-Right Savings display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      currency.format(safeBalance),
                      style: context.textStyles.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Bottom-Right Corner Savings Display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Savings',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(safeSavings),
                        style: context.textStyles.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated card for Expenses incurred in the current calendar month.
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
    final safeExpense = (monthlyExpense.isNaN || monthlyExpense < 0) ? 0.0 : monthlyExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today,
                  size: AppSizes.iconMd, color: Colors.redAccent),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses ($monthName)',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(safeExpense),
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final CurrencyFormatter currency;

  const _RecentTransactionsList({
    required this.transactions,
    required this.currency,
  });

  Map<String, List<TransactionModel>> _groupTransactions(List<TransactionModel> txList) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();

    for (final tx in txList) {
      final date = tx.date;
      String groupKey;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
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
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: context.colors.outline,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'No transactions in the past 7 days',
                style: context.textStyles.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap Add Balance above or the + button below to log your entries.',
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => const AddTransactionSheet(
                      initialType: TransactionType.expense,
                      lockType: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = _groupTransactions(transactions);
    final groupKeys = grouped.keys.toList();

    return Column(
      children: [
        for (final groupKey in groupKeys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _RecentDayCard(
              groupKey: groupKey,
              items: grouped[groupKey] ?? [],
              currency: currency,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
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

    final String? subtitleText = dayIncome > 0
        ? '+${widget.currency.format(dayIncome)}'
        : null;

    final rightSideAmountStr = dayExpense > 0
        ? widget.currency.format(dayExpense)
        : (dayIncome > 0 ? '+${widget.currency.format(dayIncome)}' : widget.currency.format(0.0));

    final rightSideColor = dayExpense > 0
        ? Colors.redAccent
        : (dayIncome > 0 ? Colors.green : theme.colorScheme.onSurfaceVariant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupKey,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitleText != null)
                          Text(
                            subtitleText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: rightSideColor,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    _TransactionTile(
                      transaction: widget.items[i],
                      currency: widget.currency,
                    ),
                    if (i < widget.items.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                ],
              ),
            ),
          ],
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
        content: Text('Are you sure you want to delete "${transaction.title}"? Your total balance will be recalculated.'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final timeStr = DateFormat.jm().format(transaction.date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 2),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, size: AppSizes.iconSm, color: color),
      ),
      title: Text(
        transaction.title,
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${transaction.category} · $timeStr',
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.format(transaction.amount.abs()),
            style: context.textStyles.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }
}
