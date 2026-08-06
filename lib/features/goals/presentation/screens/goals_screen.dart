import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../data/goal_providers.dart';
import '../../domain/goal_model.dart';
import '../widgets/add_goal_sheet.dart';

/// Wishlist Goals screen wrapped in Finnect 3D cosmic background.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _showAddGoalSheet(BuildContext context, WidgetRef ref,
      [GoalModel? existingGoal]) {
    showAppModalBottomSheet(
      context: context,
      ref: ref,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) => AddGoalSheet(existingGoal: existingGoal),
    );
  }

  void _checkGoalAchievementNotifications(
    BuildContext context,
    WidgetRef ref,
    List<GoalModel> goals,
    double totalSavings,
  ) {
    for (final goal in goals) {
      if (!goal.isPurchased &&
          totalSavings >= goal.targetPrice &&
          !goal.notified) {
        // Mark as notified so it triggers only once
        final updated = goal.copyWith(notified: true);
        ref.read(goalControllerProvider.notifier).updateGoal(updated);

        // Send local notification banner
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎉 Goal Achieved!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              'You now have enough savings to buy your "${goal.title}".'),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E88E5),
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final currency = CurrencyFormatter();
    final totalSavings = summary.savings; // Total Savings transferred

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Wishlist Goals'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddGoalSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Goal'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: goalsAsync.when(
          data: (goals) {
            _checkGoalAchievementNotifications(
                context, ref, goals, totalSavings);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.md,
                AppSizes.lg,
                AppSizes.xxl + AppSizes.xl,
              ),
              children: [
                // Top Card: Total Savings (Transferred to Savings)
                _TotalSavingsCard(
                  currency: currency,
                  totalSavings: totalSavings,
                ),
                const SizedBox(height: AppSizes.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Wishlist (${goals.length})',
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                if (goals.isEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.stars_outlined,
                            size: 48,
                            color: context.colors.outline,
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'No Wishlist Goals Yet',
                            style: context.textStyles.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items you want to buy and move balance to savings to unlock goals!',
                            textAlign: TextAlign.center,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          ElevatedButton.icon(
                            onPressed: () => _showAddGoalSheet(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Goal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  for (final goal in goals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: _GoalCard(
                        goal: goal,
                        totalSavings: totalSavings,
                        currency: currency,
                        onEdit: () => _showAddGoalSheet(context, ref, goal),
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => const AppLoader(),
          error: (err, stack) => Center(
            child: Text('Error loading goals: $err'),
          ),
        ),
      ),
    );
  }
}

/// Top card displaying current Total Savings
class _TotalSavingsCard extends StatelessWidget {
  final CurrencyFormatter currency;
  final double totalSavings;

  const _TotalSavingsCard({
    required this.currency,
    required this.totalSavings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Savings',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            currency.format(totalSavings < 0 ? 0.0 : totalSavings),
            style: context.textStyles.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Goal Wishlist Card displaying item progress bar, target price, and remaining amount.
class _GoalCard extends ConsumerWidget {
  final GoalModel goal;
  final double totalSavings;
  final CurrencyFormatter currency;
  final VoidCallback onEdit;

  const _GoalCard({
    required this.goal,
    required this.totalSavings,
    required this.currency,
    required this.onEdit,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(goalControllerProvider.notifier)
                  .deleteGoal(goal.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Goal "${goal.title}" deleted.'),
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

  void _togglePurchased(WidgetRef ref) {
    final updated = goal.copyWith(isPurchased: !goal.isPurchased);
    ref.read(goalControllerProvider.notifier).updateGoal(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAchieved = totalSavings >= goal.targetPrice;
    final double rawProgress =
        goal.targetPrice > 0 ? (totalSavings / goal.targetPrice) : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final double remaining =
        (goal.targetPrice - totalSavings).clamp(0.0, double.infinity);
    final pctInt = (progress * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isAchieved
                      ? Colors.green.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    isAchieved ? Icons.stars : Icons.card_giftcard,
                    color:
                        isAchieved ? Colors.green : theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: goal.isPurchased
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (goal.isPurchased)
                            const Chip(
                              label: Text('Purchased ✔'),
                              visualDensity: VisualDensity.compact,
                            )
                          else if (isAchieved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🎉 Ready to Buy!',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (goal.description != null &&
                          goal.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          goal.description ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${currency.format(goal.targetPrice)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'purchased') _togglePurchased(ref);
                    if (val == 'delete') _confirmDelete(context, ref);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'purchased',
                      child: Text(goal.isPurchased
                          ? 'Mark as Not Purchased'
                          : 'Mark as Purchased'),
                    ),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Goal')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Goal',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved: ${currency.format(totalSavings < 0 ? 0.0 : totalSavings)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '$pctInt%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isAchieved ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved ? Colors.green : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Remaining Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAchieved
                      ? 'You have saved enough for this goal!'
                      : 'Remaining: ${currency.format(remaining)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isAchieved
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isAchieved ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
