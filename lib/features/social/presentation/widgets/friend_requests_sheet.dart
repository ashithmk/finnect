import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/extensions.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/social_providers.dart';
import '../../domain/social_models.dart';

/// Modal sheet displaying Search, Incoming Requests, and Outgoing Pending Requests with Cancel support.
class FriendRequestsSheet extends ConsumerStatefulWidget {
  const FriendRequestsSheet({super.key});

  @override
  ConsumerState<FriendRequestsSheet> createState() => _FriendRequestsSheetState();
}

class _FriendRequestsSheetState extends ConsumerState<FriendRequestsSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    final sentRequestsAsync = ref.watch(sentFriendRequestsProvider);
    final query = ref.watch(userSearchQueryProvider);
    final isSearching = query.trim().isNotEmpty;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: mediaQuery.viewInsets.bottom + AppSizes.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Friend Requests & Add',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // Search Bar to Add Friends by Username
          TextField(
            controller: _searchController,
            onChanged: (val) {
              ref.read(userSearchQueryProvider.notifier).state = val;
            },
            decoration: InputDecoration(
              hintText: 'Search users by @username, name, or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(userSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Scrollable List Content
          Expanded(
            child: ListView(
              children: [
                if (isSearching) ...[
                  Text(
                    'Search Results',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  const _SheetSearchResultsList(),
                  const SizedBox(height: AppSizes.lg),
                ] else ...[
                  // 1. Incoming Friend Requests
                  Text(
                    'Incoming Requests',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  pendingRequestsAsync.when(
                    data: (requests) {
                      if (requests.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          child: Text(
                            'No incoming friend requests.',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: requests.map((user) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.formattedUsername),
                              trailing: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 135),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent),
                                      tooltip: 'Decline',
                                      onPressed: () async {
                                        final success = await ref
                                            .read(socialControllerProvider.notifier)
                                            .rejectFriendRequest(user.uid);
                                        if (context.mounted && success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Declined request from ${user.displayName}.'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onPressed: () async {
                                        final success = await ref
                                            .read(socialControllerProvider.notifier)
                                            .acceptFriendRequest(user.uid);
                                        if (context.mounted && success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('You are now friends with ${user.displayName}! 🎉'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check, size: 14),
                                      label: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading requests: $err'),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // 2. Sent / Outgoing Pending Requests (with Cancel Request button)
                  Text(
                    'Sent Pending Requests',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  sentRequestsAsync.when(
                    data: (sentRequests) {
                      if (sentRequests.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          child: Text(
                            'No sent pending requests.',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: sentRequests.map((user) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                child: Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.formattedUsername),
                              trailing: SizedBox(
                                width: 130,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onPressed: () async {
                                    final success = await ref
                                        .read(socialControllerProvider.notifier)
                                        .cancelFriendRequest(user.uid);
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cancelled request sent to ${user.displayName}.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 14),
                                  label: const Text('Cancel'),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading sent requests: $err'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSearchResultsList extends ConsumerWidget {
  const _SheetSearchResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(userSearchResultsProvider);
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.uid ?? '';

    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Text('No matching users found.', textAlign: TextAlign.center),
          );
        }

        return Column(
          children: results.map((user) {
            final isAccepted = user.status == FriendshipStatus.accepted;
            final isPending = user.status == FriendshipStatus.pending;
            final isOutgoing = isPending && user.requesterId == currentUserId;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.formattedUsername),
                trailing: SizedBox(
                  width: 110,
                  child: isAccepted
                      ? const Text('Friends ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                      : isOutgoing
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(socialControllerProvider.notifier)
                                    .cancelFriendRequest(user.uid);
                              },
                              child: const Text('Cancel'),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onPressed: () async {
                                final success = await ref
                                    .read(socialControllerProvider.notifier)
                                    .sendFriendRequest(user.uid);
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Friend request sent to ${user.displayName}!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.person_add, size: 14),
                              label: const Text('Add'),
                            ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Search error: $err'),
    );
  }
}
