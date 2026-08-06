import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';

/// Redesigned Balance Details Modal Sheet displaying:
/// - Current Net Total Balance
/// - "To Get" (Lent out) & "To Give" (Borrowed) metrics
/// - Interactive itemized dues cards with `-` (minus got back) and `✓` (tick close account) controls.
class BalanceDetailsSheet extends ConsumerStatefulWidget {
  const BalanceDetailsSheet({super.key});

  @override
  ConsumerState<BalanceDetailsSheet> createState() => _BalanceDetailsSheetState();
}

class _BalanceDetailsSheetState extends ConsumerState<BalanceDetailsSheet> {
  int _selectedFilterIndex = 0; // 0: All, 1: To Get (Lend), 2: To Give (Borrow), 3: Closed

  void _openRepaymentDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
    bool isLend,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _RepaymentDialog(tx: tx, isLend: isLend),
    );
  }

  void _openCloseAccountDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
    bool isLend,
  ) {
    final remaining = tx.remainingAmount;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF252830)
              : Colors.white,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF005236),
                child: Icon(Icons.check, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Close Account?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isLend
                ? 'Are you sure you want to mark "${tx.title}" as fully settled/closed? Remaining ₹${remaining.toStringAsFixed(2)} will be added to your Total Balance.'
                : 'Are you sure you want to mark "${tx.title}" as fully settled/closed? Dues will be marked paid off.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005236),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();

                final updatedTx = tx.copyWith(
                  repaidAmount: tx.amount,
                  isClosed: true,
                );

                final success = await ref
                    .read(transactionControllerProvider.notifier)
                    .updateTransaction(updatedTx);

                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Account "${tx.title}" closed! Total Balance updated.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Confirm Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLendBorrowTile(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
    CurrencyFormatter currency,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catLower = tx.category.toLowerCase();
    final isLend = catLower == 'lend' || catLower == 'to get';
    final itemColor = isLend ? const Color(0xFF005236) : const Color(0xFFBA1A1A);
    final dateStr = DateFormat.MMMd().format(tx.date);

    final originalAmount = tx.amount;
    final repaidAmount = tx.repaidAmount;
    final remaining = tx.remainingAmount;
    final isClosed = tx.isClosed;

    final progressRatio = originalAmount > 0 ? (repaidAmount / originalAmount).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: itemColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isLend ? Icons.call_made_rounded : Icons.call_received_rounded,
                  size: 16,
                  color: itemColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1C23),
                      ),
                    ),
                    Text(
                      '${isLend ? "To Get (Lent)" : "To Give (Borrowed)"} · $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : const Color(0xFF757885),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(remaining),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isClosed ? Colors.grey : itemColor,
                    ),
                  ),
                  if (repaidAmount > 0)
                    Text(
                      'Got ${currency.format(repaidAmount)} / ${currency.format(originalAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF757885),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (!isClosed && originalAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 6,
                backgroundColor: itemColor.withValues(alpha: 0.15),
                color: itemColor,
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005236).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF005236).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF005236)),
                      SizedBox(width: 4),
                      Text(
                        'Account Closed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF005236),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  repaidAmount > 0
                      ? 'Remaining: ${currency.format(remaining)}'
                      : 'Total: ${currency.format(originalAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF757885),
                  ),
                ),

              if (!isClosed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openRepaymentDialog(context, ref, tx, isLend),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withValues(alpha: 0.20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    InkWell(
                      onTap: () => _openCloseAccountDialog(context, ref, tx, isLend),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF005236).withValues(alpha: 0.20),
                          border: Border.all(
                            color: const Color(0xFF005236).withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF005236),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyFormatter();
    final summary = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final safeBalance = (summary.totalBalance.isNaN || summary.totalBalance < 0)
        ? 0.0
        : summary.totalBalance;
    final safeToGet = (summary.toGet.isNaN || summary.toGet < 0) ? 0.0 : summary.toGet;
    final safeToGive = (summary.toGive.isNaN || summary.toGive < 0) ? 0.0 : summary.toGive;

    final allLendBorrow = summary.lendBorrowTransactions;
    final activeLend = allLendBorrow
        .where((tx) =>
            !tx.isClosed &&
            (tx.category.toLowerCase() == 'lend' || tx.category.toLowerCase() == 'to get'))
        .toList();
    final activeBorrow = allLendBorrow
        .where((tx) =>
            !tx.isClosed &&
            (tx.category.toLowerCase() == 'borrow' || tx.category.toLowerCase() == 'to give'))
        .toList();
    final closedItems = allLendBorrow.where((tx) => tx.isClosed).toList();

    List<TransactionModel> displayedItems;
    switch (_selectedFilterIndex) {
      case 1:
        displayedItems = activeLend;
        break;
      case 2:
        displayedItems = activeBorrow;
        break;
      case 3:
        displayedItems = closedItems;
        break;
      case 0:
      default:
        displayedItems = allLendBorrow;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance & Dues',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1C23),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Net Total Balance Primary Hero Card
              FinnectGlassCard(
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(20),
                glassColor: isDark
                    ? const Color(0xFF252830)
                    : const Color(0xFF1A1C23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Net Total Balance',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currency.format(safeBalance),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dues Metrics Grid: "To Get" & "To Give"
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005236).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF005236).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(0xFF005236),
                                child: Icon(Icons.call_made_rounded, size: 10, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'To Get',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF005236),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(safeToGet),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF005236),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBA1A1A).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(0xFFBA1A1A),
                                child: Icon(Icons.call_received_rounded, size: 10, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'To Give',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFBA1A1A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(safeToGive),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFFBA1A1A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Filter Bar for Dues List
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 0, label: Text('All')),
                  ButtonSegment<int>(value: 1, label: Text('To Get')),
                  ButtonSegment<int>(value: 2, label: Text('To Give')),
                  ButtonSegment<int>(value: 3, label: Text('Closed')),
                ],
                selected: {_selectedFilterIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedFilterIndex = set.first);
                },
              ),
              const SizedBox(height: 16),

              if (displayedItems.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No items found under this filter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : const Color(0xFF757885),
                    ),
                  ),
                ),
              ] else ...[
                for (final tx in displayedItems)
                  _buildLendBorrowTile(context, ref, tx, currency),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RepaymentDialog extends ConsumerStatefulWidget {
  final TransactionModel tx;
  final bool isLend;

  const _RepaymentDialog({
    required this.tx,
    required this.isLend,
  });

  @override
  ConsumerState<_RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends ConsumerState<_RepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = widget.tx.remainingAmount;
    final isLend = widget.isLend;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isDark ? const Color(0xFF252830) : Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isLend
                ? const Color(0xFF005236).withValues(alpha: 0.2)
                : const Color(0xFFBA1A1A).withValues(alpha: 0.2),
            child: Icon(
              Icons.remove,
              size: 18,
              color: isLend ? const Color(0xFF005236) : const Color(0xFFBA1A1A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLend ? 'Money Got Back' : 'Paid Dues Back',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1C23),
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.tx.title} · Outstanding: ₹${remaining.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF757885),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: isLend ? 'Amount Got Back' : 'Amount Paid Back',
                prefixText: '₹ ',
                hintText: '0.00',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final parsed = double.tryParse(val.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount > 0';
                }
                if (parsed > remaining + 0.01) {
                  return 'Cannot exceed remaining ₹${remaining.toStringAsFixed(2)}';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isLend ? const Color(0xFF005236) : const Color(0xFFBA1A1A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final enteredAmount = double.parse(_controller.text.trim());
            Navigator.of(context).pop();

            final newRepaid = widget.tx.repaidAmount + enteredAmount;
            final shouldClose = newRepaid >= (widget.tx.amount - 0.01);

            final updatedTx = widget.tx.copyWith(
              repaidAmount: newRepaid,
              isClosed: shouldClose,
            );

            final success = await ref
                .read(transactionControllerProvider.notifier)
                .updateTransaction(updatedTx);

            if (context.mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isLend
                        ? 'Got ₹${enteredAmount.toStringAsFixed(2)} back! Total Balance updated.'
                        : 'Paid ₹${enteredAmount.toStringAsFixed(2)} back! Total Balance updated.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Save Repayment'),
        ),
      ],
    );
  }
}
