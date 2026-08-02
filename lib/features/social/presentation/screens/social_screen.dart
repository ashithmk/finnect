import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/widgets/finnect_3d_background.dart';
import '../../data/social_providers.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/friend_requests_sheet.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const CreateGroupSheet(),
    );
  }

  void _openFriendRequestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => const FriendRequestsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    final pendingCount = pendingRequestsAsync.value?.length ?? 0;

    return Finnect3DBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Groups'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _openFriendRequestsSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 24),
                      if (pendingCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Groups', icon: Icon(Icons.groups_outlined, size: 20)),
              Tab(text: 'Friends', icon: Icon(Icons.person_outline, size: 20)),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GroupsTabList(onCreateGroup: () => _openCreateGroupSheet(context)),
              const _FriendsTabList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friends tab list displaying ONLY accepted friends
class _FriendsTabList extends ConsumerWidget {
  const _FriendsTabList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsStreamProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: context.colors.outline),
                      const SizedBox(height: AppSizes.md),
                      Text('No Friends ', style: context.textStyles.titleMedium),
                      const SizedBox(height: 4),
                      
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Friends (${friends.length})',
                  style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.sm),
                for (final friend in friends) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : 'F',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(friend.formattedUsername),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Friend',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading friends: $err')),
        ),
      ],
    );
  }
}

/// Groups tab list
class _GroupsTabList extends ConsumerWidget {
  final VoidCallback onCreateGroup;

  const _GroupsTabList({required this.onCreateGroup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsStreamProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Groups',
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 64, color: context.colors.outline),
                      const SizedBox(height: AppSizes.md),
                      Text('No Groups Yet', style: context.textStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Create a group to start splitting bills with friends!',
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      ElevatedButton.icon(
                        onPressed: onCreateGroup,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Group'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: groups.map((group) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSizes.md),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (group.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(group.description),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberIds.length} members',
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.pushNamed(
                        RouteNames.groupDetail,
                        pathParameters: {'id': group.id},
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading groups: $err'),
          ),
        ),
      ],
    );
  }
}
