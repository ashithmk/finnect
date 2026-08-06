import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../data/transaction_providers.dart';
import '../../domain/transaction_model.dart';
import '../widgets/add_transaction_sheet.dart';

/// History Screen strictly adhering to `finnect_design/history_reverted_footer/code.html` and Google Stitch Light theme.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedMonthKey; // 'yyyy-MM' (e.g. '2026-07')

  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    final now = DateTime.now();

    for (final tx in transactions) {
      final date = tx.date;
      String groupKey;

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groupKey = 'TODAY, ${DateFormat('MMM d').format(date).toUpperCase()}';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        groupKey = 'YESTERDAY, ${DateFormat('MMM d').format(date).toUpperCase()}';
      } else {
        groupKey = DateFormat('EEEE, MMM d').format(date).toUpperCase();
      }

      grouped.putIfAbsent(groupKey, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = CurrencyFormatter();
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: transactionsAsync.when(
            data: (allTransactions) {
              if (allTransactions.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: 'No History Yet',
                      subtitle:
                          'Tap the + button below or Add Balance on Home to log entries.',
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
                  ),
                );
              }

              final Map<String, String> monthOptions = {};
              monthOptions[currentMonthKey] =
                  DateFormat('MMMM').format(DateTime.now()).toUpperCase();

              for (final tx in allTransactions) {
                final mKey = DateFormat('yyyy-MM').format(tx.date);
                final mLabel =
                    DateFormat('MMMM').format(tx.date).toUpperCase();
                monthOptions.putIfAbsent(mKey, () => mLabel);
              }

              final activeMonthKey = _selectedMonthKey ?? currentMonthKey;
              final selectedMonthLabel =
                  monthOptions[activeMonthKey] ?? monthOptions[currentMonthKey] ?? 'THIS MONTH';

              final filteredTransactions = allTransactions.where((tx) {
                final monthKey = DateFormat('yyyy-MM').format(tx.date);
                return monthKey == activeMonthKey;
              }).toList();

              final grouped = _groupTransactions(filteredTransactions);
              final groupKeys = grouped.keys.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'History',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                setState(() => _selectedMonthKey = val);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              itemBuilder: (ctx) => monthOptions.entries.map((entry) {
                                final isCurrent = entry.key == currentMonthKey;
                                return PopupMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    isCurrent ? '${entry.value} (CURRENT)' : entry.value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                              child: FinnectGlassCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                borderRadius: BorderRadius.circular(9999),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedMonthLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.expand_more_rounded,
                                      size: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions found for $selectedMonthLabel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              8,
                              24,
                              120,
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
                                padding: const EdgeInsets.only(bottom: 16),
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
      ),
    );
  }
}

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
  State<_DailySummaryExpandableCard> createState() =>
      _DailySummaryExpandableCardState();
}

class _DailySummaryExpandableCardState
    extends State<_DailySummaryExpandableCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.groupKey.startsWith('TODAY');
  }

  @override
  Widget build(BuildContext context) {
    return FinnectGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                border: _isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.groupKey,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.dayTotal < 0 ? "-" : "+"}${widget.currency.format(widget.dayTotal.abs())}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.dayTotal < 0
                          ? AppColors.textPrimary
                          : AppColors.income,
                    ),
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
                    _TransactionItemTile(
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

class _TransactionItemTile extends ConsumerWidget {
  final TransactionModel transaction;
  final CurrencyFormatter currency;

  const _TransactionItemTile({
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
      return Icons.arrow_downward_rounded;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isIncome
                      ? AppColors.income.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.60),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F2687).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(transaction.category),
                  size: 22,
                  color: isIncome ? AppColors.income : AppColors.textPrimary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? "+" : "-"}${currency.format(transaction.amount.abs())}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isIncome ? AppColors.income : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
