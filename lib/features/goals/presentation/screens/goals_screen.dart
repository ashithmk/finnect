import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../../core/widgets/finnect_glass_card.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../data/goal_providers.dart';
import '../../domain/goal_model.dart';
import '../widgets/add_goal_sheet.dart';

/// Wishlist Goals screen wrapped in Finnect 3D background.
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
        final updated = goal.copyWith(notified: true);
        ref.read(goalControllerProvider.notifier).updateGoal(updated);

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
                backgroundColor: AppColors.income,
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
    final totalSavings = summary.savings;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Wishlist Goals',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddGoalSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Goal'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                if (goals.isEmpty) ...[
                  FinnectGlassCard(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.stars_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'No Wishlist Goals Yet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add items you want to buy and move balance to savings to unlock goals!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        ElevatedButton.icon(
                          onPressed: () => _showAddGoalSheet(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Goal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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

class _TotalSavingsCard extends StatelessWidget {
  final CurrencyFormatter currency;
  final double totalSavings;

  const _TotalSavingsCard({
    required this.currency,
    required this.totalSavings,
  });

  @override
  Widget build(BuildContext context) {
    return FinnectGlassCard(
      glassColor: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Savings',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(totalSavings < 0 ? 0.0 : totalSavings),
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

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
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
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
    final isAchieved = totalSavings >= goal.targetPrice;
    final double rawProgress =
        goal.targetPrice > 0 ? (totalSavings / goal.targetPrice) : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final double remaining =
        (goal.targetPrice - totalSavings).clamp(0.0, double.infinity);
    final pctInt = (progress * 100).toInt();

    return FinnectGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isAchieved
                    ? AppColors.income.withValues(alpha: 0.15)
                    : AppColors.glassSubtleFill,
                child: Icon(
                  isAchieved ? Icons.stars_rounded : Icons.card_giftcard_rounded,
                  color: isAchieved ? AppColors.income : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                              color: AppColors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🎉 Ready to Buy!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.income,
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${currency.format(goal.targetPrice)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                          style: TextStyle(color: AppColors.expense))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${currency.format(totalSavings < 0 ? 0.0 : totalSavings)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isAchieved ? AppColors.income : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? AppColors.income : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAchieved
                    ? 'You have saved enough for this goal!'
                    : 'Remaining: ${currency.format(remaining)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isAchieved
                      ? AppColors.income
                      : AppColors.textSecondary,
                  fontWeight:
                      isAchieved ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
