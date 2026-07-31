import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/currency_formatter.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/social_providers.dart';
import '../../domain/social_models.dart';
import '../widgets/add_split_bill_sheet.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  void _openAddSplitBillSheet(BuildContext context, GroupModel group, List<UserFriendInfo> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => AddSplitBillSheet(group: group, members: members),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = CurrencyFormatter();
    final groupAsync = ref.watch(groupDetailsProvider(groupId));
    final billsAsync = ref.watch(groupBillsStreamProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.uid ?? 'demo_uid_1';
    final socialRepository = ref.watch(socialRepositoryProvider);

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: groupAsync.when(
            data: (g) => Text(g?.name ?? 'Group Details'),
            loading: () => const Text('Loading group...'),
            error: (_, __) => const Text('Group Details'),
          ),
        ),
        body: groupAsync.when(
          data: (group) {
            if (group == null) {
              return const Center(child: Text('Group not found'));
            }

            return FutureBuilder<List<UserFriendInfo>>(
              future: socialRepository.getGroupMembers(group.memberIds),
              builder: (context, membersSnapshot) {
                final members = membersSnapshot.data ?? [];
                final memberMap = {for (var m in members) m.uid: m};

                return ListView(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  children: [
                    // Group Header Card
                    _GroupHeaderCard(
                      group: group,
                      members: members,
                      currentUserId: currentUserId,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split Bills & Expenses',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openAddSplitBillSheet(context, group, members),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Split Bill'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Group Bills Feed
                    billsAsync.when(
                      data: (bills) {
                        if (bills.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.xl),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: context.colors.outline,
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  Text(
                                    'No bills split yet in this group',
                                    style: context.textStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Split Bill" above to add meals, rent, or trip bills!',
                                    textAlign: TextAlign.center,
                                    style: context.textStyles.bodySmall?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: bills.map((bill) {
                            return _GroupBillCard(
                              bill: bill,
                              group: group,
                              memberMap: memberMap,
                              currentUserId: currentUserId,
                              currency: currency,
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Text('Error loading bills: $err'),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading group: $err')),
        ),
      ),
    );
  }
}

class _GroupHeaderCard extends StatelessWidget {
  final GroupModel group;
  final List<UserFriendInfo> members;
  final String currentUserId;

  const _GroupHeaderCard({
    required this.group,
    required this.members,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3F51B5), // Indigo
            Color(0xFF7E57C2), // Violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: const Icon(Icons.group_work, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: context.textStyles.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.description,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Members (${members.length}):',
            style: context.textStyles.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: members.map((m) {
              final isMe = m.uid == currentUserId;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? Colors.white : Colors.white30,
                    width: isMe ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  isMe ? '${m.displayName} (You)' : '${m.displayName} (${m.formattedUsername})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GroupBillCard extends ConsumerWidget {
  final GroupBillModel bill;
  final GroupModel group;
  final Map<String, UserFriendInfo> memberMap;
  final String currentUserId;
  final CurrencyFormatter currency;

  const _GroupBillCard({
    required this.bill,
    required this.group,
    required this.memberMap,
    required this.currentUserId,
    required this.currency,
  });

  Future<void> _settleShare(BuildContext context, WidgetRef ref, double amount) async {
    final success = await ref.read(socialControllerProvider.notifier).settleBillShare(
          groupId: group.id,
          groupName: group.name,
          bill: bill,
        );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${currency.format(amount)} settled! Reduced from balance and added to Expenses. 📉✨',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final payer = memberMap[bill.paidByUserId];
    final payerName = bill.paidByUserId == currentUserId
        ? 'You'
        : (payer?.displayName ?? 'Member');

    // Find current user's share
    final myShareIndex = bill.shares.indexWhere((s) => s.userId == currentUserId);
    final myShare = myShareIndex != -1 ? bill.shares[myShareIndex] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Title & Amount Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.receipt_long,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.title,
                              style: context.textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Paid by $payerName',
                              style: context.textStyles.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(bill.totalAmount),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),

            // Member Shares Breakdown
            Text(
              'Split Shares:',
              style: context.textStyles.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            for (final share in bill.shares) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      share.userId == currentUserId
                          ? '• You'
                          : '• ${memberMap[share.userId]?.displayName ?? 'Member'}',
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: share.userId == currentUserId
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          currency.format(share.amount),
                          style: context.textStyles.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (share.isSettled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Settled',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Prominent Settle Button for current user if unpaid
            if (myShare != null && !myShare.isSettled) ...[
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _settleShare(context, ref, myShare.amount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Settle Share (${currency.format(myShare.amount)})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
