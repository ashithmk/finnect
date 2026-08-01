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
import '../../../../core/widgets/loaders.dart';
import '../../data/transaction_providers.dart';
import '../../domain/transaction_model.dart';
import '../widgets/add_transaction_sheet.dart';

/// History screen with Finnect 3D background, month filter, and daily aggregated summary cards.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedMonthKey; // 'yyyy-MM' (e.g. '2026-07')

  Map<String, List<TransactionModel>> _groupTransactions(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();

    for (final tx in transactions) {
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
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = CurrencyFormatter();
    final theme = Theme.of(context);
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.navTransactions), // 'History'
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.sm),
              child: TextButton.icon(
                onPressed: () => context.push(RouteNames.goals),
                icon: const Icon(Icons.stars, color: Colors.amberAccent, size: 20),
                label: const Text(
                  'Goals',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: transactionsAsync.when(
          data: (allTransactions) {
            if (allTransactions.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: EmptyState(
                    icon: Icons.history_outlined,
                    title: 'No History Yet',
                    subtitle: 'Tap the + button below or Add Balance on Home to log entries.',
                    actionLabel: 'Add Expense',
                    onAction: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => const AddTransactionSheet(
                          initialType: TransactionType.expense,
                          lockType: true,
                        ),
                      );
                    },
                  ),
                ),
              );
            }

            // Extract unique months for Month Filter (Current month first, followed by previous months)
            final Map<String, String> monthOptions = {};
            monthOptions[currentMonthKey] = DateFormat.yMMMM().format(DateTime.now());

            for (final tx in allTransactions) {
              final mKey = DateFormat('yyyy-MM').format(tx.date);
              final mLabel = DateFormat.yMMMM().format(tx.date);
              monthOptions.putIfAbsent(mKey, () => mLabel);
            }

            final activeMonthKey = _selectedMonthKey ?? currentMonthKey;

            // Filter transactions by selected month
            final filteredTransactions = allTransactions.where((tx) {
              final monthKey = DateFormat('yyyy-MM').format(tx.date);
              return monthKey == activeMonthKey;
            }).toList();

            final grouped = _groupTransactions(filteredTransactions);
            final groupKeys = grouped.keys.toList();

            return Column(
              children: [
                // Compact Month Selector Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: monthOptions.containsKey(activeMonthKey) ? activeMonthKey : currentMonthKey,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                            dropdownColor: theme.colorScheme.surface,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            items: monthOptions.entries.map((entry) {
                              final isCurrent = entry.key == currentMonthKey;
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  isCurrent ? '${entry.value} (Current)' : entry.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMonthKey = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions found for ${monthOptions[_selectedMonthKey]}',
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg,
                            AppSizes.sm,
                            AppSizes.lg,
                            AppSizes.xxl + AppSizes.xl,
                          ),
                          itemCount: groupKeys.length,
                          itemBuilder: (ctx, groupIndex) {
                            final groupKey = groupKeys[groupIndex];
                            final groupItems = grouped[groupKey] ?? [];

                            double dayTotal = 0.0;
                            int expenseCount = 0;
                            for (final item in groupItems) {
                              if (item.type == TransactionType.income) {
                                dayTotal += item.amount;
                              } else {
                                dayTotal -= item.amount;
                                expenseCount++;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.md),
                              child: _DailySummaryExpandableCard(
                                groupKey: groupKey,
                                dayTotal: dayTotal,
                                items: groupItems,
                                expenseCount: expenseCount,
                                currency: currency,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const AppLoader(),
          error: (err, stack) => Center(
            child: Text('Error loading history: $err'),
          ),
        ),
      ),
    );
  }
}

/// Expandable Daily Summary Card. Displays day name + net day total, and expands to reveal individual items.
class _DailySummaryExpandableCard extends StatefulWidget {
  final String groupKey;
  final double dayTotal;
  final List<TransactionModel> items;
  final int expenseCount;
  final CurrencyFormatter currency;

  const _DailySummaryExpandableCard({
    required this.groupKey,
    required this.dayTotal,
    required this.items,
    required this.expenseCount,
    required this.currency,
  });

  @override
  State<_DailySummaryExpandableCard> createState() => _DailySummaryExpandableCardState();
}

class _DailySummaryExpandableCardState extends State<_DailySummaryExpandableCard> {
  // Expand today's card by default
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.groupKey == 'Today';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Daily Summary Header Row (Tap to expand/collapse)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.calendar_today,
                      size: AppSizes.iconSm,
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
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} ${widget.items.length == 1 ? "entry" : "entries"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.currency.format(widget.dayTotal.abs()),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.dayTotal >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Hide Details' : 'View Expenses',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
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
                ],
              ),
            ),
          ),

          // Expanded Items List
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    _TransactionListTile(
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

class _TransactionListTile extends ConsumerWidget {
  final TransactionModel transaction;
  final CurrencyFormatter currency;

  const _TransactionListTile({
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
        radius: 18,
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
