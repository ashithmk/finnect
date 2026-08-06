import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../../core/widgets/loaders.dart';
import '../../../transactions/data/transaction_providers.dart';
import '../../data/goal_providers.dart';
import '../../domain/goal_model.dart';
import '../widgets/add_goal_sheet.dart';

/// Redesigned Liquid Minimalist Goals Screen strictly matching `finnect_design/goal/code.html` and `DESIGN.md`.
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
                backgroundColor: const Color(0xFF009668),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF191C1D)),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(
            'Goals',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1D),
            ),
          ),
          centerTitle: false,
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4648D4).withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showAddGoalSheet(context, ref),
            backgroundColor: const Color(0xFF000000),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
        body: goalsAsync.when(
          data: (goals) {
            _checkGoalAchievementNotifications(
                context, ref, goals, totalSavings);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                120,
              ),
              children: [
                // ── Hero Total Savings Card ──
                _TotalSavingsCard(
                  currency: currency,
                  totalSavings: totalSavings,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Goals (${goals.length})',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191C1D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (goals.isEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.65),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.stars_outlined,
                              size: 48,
                              color: Color(0xFF4648D4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Wishlist Goals Yet',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Set savings goals for items you want to buy and track your progress live!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF4C4546),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddGoalSheet(context, ref),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create First Goal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF000000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  for (final goal in goals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _LiquidGoalCard(
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
    final safeSavings = totalSavings < 0 ? 0.0 : totalSavings;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.70),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SAVINGS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: const Color(0xFF4C4546),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(safeSavings),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191C1D),
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6063EE).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 24,
                  color: Color(0xFF4648D4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidGoalCard extends ConsumerWidget {
  final GoalModel goal;
  final double totalSavings;
  final CurrencyFormatter currency;
  final VoidCallback onEdit;

  const _LiquidGoalCard({
    required this.goal,
    required this.totalSavings,
    required this.currency,
    required this.onEdit,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Goal?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _togglePurchased(WidgetRef ref) {
    final updated = goal.copyWith(isPurchased: !goal.isPurchased);
    ref.read(goalControllerProvider.notifier).updateGoal(updated);
  }

  IconData _getGoalIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('macbook') || lower.contains('laptop') || lower.contains('pc') || lower.contains('phone')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('emergency') || lower.contains('fund') || lower.contains('shield') || lower.contains('insurance')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('vacation') || lower.contains('trip') || lower.contains('travel') || lower.contains('flight')) {
      return Icons.flight_takeoff_rounded;
    }
    if (lower.contains('car') || lower.contains('bike') || lower.contains('vehicle')) {
      return Icons.directions_car_rounded;
    }
    return Icons.stars_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAchieved = totalSavings >= goal.targetPrice;
    final double rawProgress =
        goal.targetPrice > 0 ? (totalSavings / goal.targetPrice) : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final pctInt = (progress * 100).toInt();

    // Determine status text, color, and gradient
    String statusText;
    Color statusColor;
    Color glowColor;
    List<Color> gradientColors;

    if (goal.isPurchased) {
      statusText = 'Purchased ✔';
      statusColor = const Color(0xFF009668);
      glowColor = const Color(0xFF009668).withValues(alpha: 0.15);
      gradientColors = [const Color(0xFF009668), const Color(0xFF4EDEAE)];
    } else if (isAchieved) {
      statusText = 'Ready to Buy! 🎉';
      statusColor = const Color(0xFF009668);
      glowColor = const Color(0xFF34D399).withValues(alpha: 0.20);
      gradientColors = [const Color(0xFF34D399), const Color(0xFF059669)];
    } else if (progress >= 0.70) {
      statusText = 'On Track';
      statusColor = const Color(0xFF059669);
      glowColor = const Color(0xFF34D399).withValues(alpha: 0.20);
      gradientColors = [const Color(0xFF34D399), const Color(0xFF059669)];
    } else if (progress >= 0.40) {
      statusText = 'Steady';
      statusColor = const Color(0xFF2563EB);
      glowColor = const Color(0xFF60A5FA).withValues(alpha: 0.20);
      gradientColors = [const Color(0xFF60A5FA), const Color(0xFF2563EB)];
    } else {
      statusText = 'Needs Attention';
      statusColor = const Color(0xFFD97706);
      glowColor = const Color(0xFFFBBF24).withValues(alpha: 0.20);
      gradientColors = [const Color(0xFFFBBF24), const Color(0xFFD97706)];
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Stack(
          children: [
            // Status Glow Orb in top-right corner
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.70),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getGoalIcon(goal.title),
                                  size: 20,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF191C1D),
                                      decoration: goal.isPurchased
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (goal.description != null &&
                                goal.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                goal.description!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF4C4546),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(totalSavings < 0 ? 0.0 : totalSavings),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF191C1D),
                            ),
                          ),
                          Text(
                            'of ${currency.format(goal.targetPrice)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: const Color(0xFF4C4546),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF4C4546)),
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

                  // Status & Percentage Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '$pctInt%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191C1D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Liquid Progress Bar
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress == 0 ? 0.02 : progress,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors.first.withValues(alpha: 0.40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
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
