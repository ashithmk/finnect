import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/widgets/aero_glass_container.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';

/// Windows 7 Liquid Glass Modal Bottom Sheet displaying:
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
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF14192E).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
    final isLend = tx.category.toLowerCase() == 'lend' ||
        tx.category.toLowerCase() == 'to get';
    final itemColor = isLend ? Colors.teal : Colors.deepOrange;
    final dateStr = DateFormat.MMMd().format(tx.date);

    final originalAmount = tx.amount;
    final repaidAmount = tx.repaidAmount;
    final remaining = tx.remainingAmount;
    final isClosed = tx.isClosed;

    final progressRatio = originalAmount > 0 ? (repaidAmount / originalAmount).clamp(0.0, 1.0) : 1.0;

    return LiquidGlassContainer(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md + 2),
      borderRadius: BorderRadius.circular(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Category Icon, & Total Dues
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: itemColor.withValues(alpha: 0.18),
                child: Icon(
                  isLend ? Icons.call_made : Icons.call_received,
                  size: 16,
                  color: itemColor,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isLend ? "To Get (Lent)" : "To Give (Borrowed)"} · $dateStr',
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
                    currency.format(remaining),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isClosed ? Colors.grey : itemColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (repaidAmount > 0)
                    Text(
                      'Got ₹${repaidAmount.toStringAsFixed(0)} / ₹${originalAmount.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Repayment Progress Bar (if active and partially repaid)
          if (!isClosed && originalAmount > 0) ...[
            const SizedBox(height: AppSizes.sm),
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

          const SizedBox(height: AppSizes.sm),

          // Bottom Action Controls Bar: Minus (-) Got Back & Tick (✓) Close Account
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Account Closed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  repaidAmount > 0
                      ? 'Remaining: ₹${remaining.toStringAsFixed(2)}'
                      : 'Total: ₹${originalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

              // Interactive Icons Row: (-) minus and (✓) tick mark
              if (!isClosed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus (-) Icon Button: Got back money
                    InkWell(
                      onTap: () => _openRepaymentDialog(context, ref, tx, isLend),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withValues(alpha: 0.20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.30),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 18,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tick (✓) Icon Button: Close Account
                    InkWell(
                      onTap: () => _openCloseAccountDialog(context, ref, tx, isLend),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withValues(alpha: 0.20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.30),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.green,
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

    final safeBalance = (summary.totalBalance.isNaN || summary.totalBalance < 0)
        ? 0.0
        : summary.totalBalance;
    final safeToGet = (summary.toGet.isNaN || summary.toGet < 0) ? 0.0 : summary.toGet;
    final safeToGive = (summary.toGive.isNaN || summary.toGive < 0) ? 0.0 : summary.toGive;

    // Filter items based on tab selection
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Header with Windows 7 Aero Glass styling
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Balance & Dues',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Current Net Total Balance Primary Windows 7 Aero Card
            AeroGlassContainer(
              padding: const EdgeInsets.all(AppSizes.lg),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF031130), // Deep Midnight Navy
                  Color(0xFF185DF1), // Electric Sapphire Blue
                  Color(0xFF0A2B7A), // Deep Blue Accent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Net Total Balance',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currency.format(safeBalance),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Dues Metrics Grid: "To Get" & "To Give"
            Row(
              children: [
                Expanded(
                  child: AeroGlassContainer(
                    padding: const EdgeInsets.all(AppSizes.md),
                    glassColor: Colors.teal.withValues(alpha: 0.15),
                    borderColor: Colors.teal.withValues(alpha: 0.45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.call_made, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'To Get',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          currency.format(safeToGet),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: AeroGlassContainer(
                    padding: const EdgeInsets.all(AppSizes.md),
                    glassColor: Colors.deepOrange.withValues(alpha: 0.15),
                    borderColor: Colors.deepOrange.withValues(alpha: 0.45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.deepOrange,
                              child: Icon(Icons.call_received, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'To Give',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          currency.format(safeToGive),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

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
            const SizedBox(height: AppSizes.md),

            // Itemized Lend / Borrow Transaction List
            if (displayedItems.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                child: Text(
                  'No items found under this filter.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
    final remaining = widget.tx.remainingAmount;
    final isLend = widget.isLend;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF14192E).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isLend ? Colors.teal.withValues(alpha: 0.2) : Colors.deepOrange.withValues(alpha: 0.2),
            child: Icon(
              Icons.remove,
              size: 18,
              color: isLend ? Colors.teal : Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLend ? 'Money Got Back' : 'Paid Dues Back',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: theme.textTheme.titleLarge?.copyWith(
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
            backgroundColor: isLend ? Colors.teal : Colors.deepOrange,
            foregroundColor: Colors.white,
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
