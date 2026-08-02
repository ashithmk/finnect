import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../../transactions/domain/transaction_model.dart';

/// Modal bottom sheet displaying Current Total Balance, "To Get" (Lent out),
/// and "To Give" (Borrowed) metrics along with itemized dues history.
class BalanceDetailsSheet extends ConsumerWidget {
  const BalanceDetailsSheet({super.key});

  Widget _buildLendBorrowTile(
    BuildContext context,
    TransactionModel tx,
    CurrencyFormatter currency,
  ) {
    final theme = Theme.of(context);
    final isLend = tx.category.toLowerCase() == 'lend' ||
        tx.category.toLowerCase() == 'to get';
    final itemColor = isLend ? Colors.teal : Colors.deepOrange;
    final dateStr = DateFormat.MMMd().format(tx.date);

    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: itemColor.withValues(alpha: 0.15),
        child: Icon(
          isLend ? Icons.call_made : Icons.call_received,
          size: 14,
          color: itemColor,
        ),
      ),
      title: Text(
        tx.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${isLend ? "To Get (Lent)" : "To Give (Borrowed)"} · $dateStr',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        currency.format(tx.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          color: itemColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = CurrencyFormatter();
    final summary = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    final safeBalance = (summary.totalBalance.isNaN || summary.totalBalance < 0)
        ? 0.0
        : summary.totalBalance;
    final safeToGet = (summary.toGet.isNaN || summary.toGet < 0) ? 0.0 : summary.toGet;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Balance',
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

            // Current Total Balance Primary Card
            Container(
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
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current  Balance',
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Dues Metrics Grid: "To Get" (Lent)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Colors.teal.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.call_made, size: 14, color: Colors.white),
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
                  const SizedBox(height: AppSizes.sm),
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
            const SizedBox(height: AppSizes.lg),

            // Itemized Lend / Borrow Transaction List
            Text(
              '',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.xs),

            if (summary.lendBorrowTransactions.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Text(
                  'No active',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < summary.lendBorrowTransactions.length; i++) ...[
                      _buildLendBorrowTile(
                        context,
                        summary.lendBorrowTransactions[i],
                        currency,
                      ),
                      if (i < summary.lendBorrowTransactions.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
