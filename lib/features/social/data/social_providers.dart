import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/social_models.dart';
import 'social_repository.dart';

/// Provider for [SocialRepository].
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseSocialRepository();
  }
  return LocalMockSocialRepository();
});

/// Search query notifier for user search
class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Search query state for user search
final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(UserSearchQueryNotifier.new);

/// Search results provider based on [userSearchQueryProvider]
final userSearchResultsProvider = FutureProvider.autoDispose<List<UserFriendInfo>>((ref) async {
  final query = ref.watch(userSearchQueryProvider);
  final user = ref.watch(currentUserProvider);
  final currentUserId = user?.uid ?? '';

  final repository = ref.watch(socialRepositoryProvider);
  return repository.searchUsers(currentUserId, query);
});

/// Friends list stream provider
final friendsStreamProvider = StreamProvider<List<UserFriendInfo>>((ref) {
  final user = ref.watch(currentUserProvider);
  final currentUserId = user?.uid ?? 'demo_uid_1';

  final repository = ref.watch(socialRepositoryProvider);
  return repository.getFriends(currentUserId);
});

/// Pending incoming friend requests stream provider
final pendingFriendRequestsProvider = StreamProvider<List<UserFriendInfo>>((ref) {
  final user = ref.watch(currentUserProvider);
  final currentUserId = user?.uid ?? 'demo_uid_1';

  final repository = ref.watch(socialRepositoryProvider);
  return repository.getPendingFriendRequests(currentUserId);
});

/// Sent/outgoing pending friend requests stream provider
final sentFriendRequestsProvider = StreamProvider<List<UserFriendInfo>>((ref) {
  final user = ref.watch(currentUserProvider);
  final currentUserId = user?.uid ?? 'demo_uid_1';

  final repository = ref.watch(socialRepositoryProvider);
  return repository.getSentFriendRequests(currentUserId);
});

/// User groups stream provider
final userGroupsStreamProvider = StreamProvider<List<GroupModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final currentUserId = user?.uid ?? 'demo_uid_1';

  final repository = ref.watch(socialRepositoryProvider);
  return repository.getUserGroups(currentUserId);
});

/// Single group details provider
final groupDetailsProvider =
    StreamProvider.family<GroupModel?, String>((ref, groupId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getGroupById(groupId);
});

/// Group bills stream provider
final groupBillsStreamProvider =
    StreamProvider.family<List<GroupBillModel>, String>((ref, groupId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getGroupBills(groupId);
});

/// Controller for executing Social, Group, and Split Bill actions.
class SocialController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Add user as friend (send request)
  Future<bool> sendFriendRequest(String targetUserId) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.sendFriendRequest(currentUserId, targetUserId);
    });
    ref.invalidate(userSearchResultsProvider);
    return !state.hasError;
  }

  /// Accept incoming friend request
  Future<bool> acceptFriendRequest(String friendId) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.acceptFriendRequest(currentUserId, friendId);
    });
    ref.invalidate(userSearchResultsProvider);
    return !state.hasError;
  }

  /// Reject incoming friend request
  Future<bool> rejectFriendRequest(String friendId) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.rejectFriendRequest(currentUserId, friendId);
    });
    ref.invalidate(userSearchResultsProvider);
    return !state.hasError;
  }

  /// Cancel outgoing friend request
  Future<bool> cancelFriendRequest(String friendId) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.cancelFriendRequest(currentUserId, friendId);
    });
    ref.invalidate(userSearchResultsProvider);
    return !state.hasError;
  }

  /// Create new group with friends
  Future<GroupModel?> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
  }) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final fullMembers = {...memberIds, currentUserId}.toList();

    final group = GroupModel(
      id: '',
      name: name.trim(),
      description: description.trim(),
      createdBy: currentUserId,
      memberIds: fullMembers,
      createdAt: DateTime.now(),
    );

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();
    GroupModel? createdGroup;

    state = await AsyncValue.guard(() async {
      createdGroup = await repository.createGroup(group);
    });

    return createdGroup;
  }

  /// Send/add split bill in a group
  Future<bool> addSplitBill({
    required String groupId,
    required String title,
    required double totalAmount,
    required String paidByUserId,
    required List<GroupBillShare> shares,
  }) async {
    final bill = GroupBillModel(
      id: '',
      groupId: groupId,
      title: title.trim(),
      totalAmount: totalAmount,
      paidByUserId: paidByUserId,
      shares: shares,
      createdAt: DateTime.now(),
    );

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await repository.addBillToGroup(bill);
    });

    return !state.hasError;
  }

  /// Settle user share in a split bill and automatically log it as an Expense transaction
  Future<bool> settleBillShare({
    required String groupId,
    required String groupName,
    required GroupBillModel bill,
  }) async {
    final user = ref.read(currentUserProvider);
    final currentUserId = user?.uid ?? 'demo_uid_1';

    final repository = ref.read(socialRepositoryProvider);
    state = const AsyncValue.loading();

    bool success = false;

    state = await AsyncValue.guard(() async {
      final settledShare = await repository.settleBillShare(
        groupId: groupId,
        billId: bill.id,
        userId: currentUserId,
      );

      if (settledShare != null) {
        // Automatically create an Expense transaction for the current user
        final txTitle = groupName.isNotEmpty
            ? '$groupName: ${bill.title}'
            : 'Split Bill: ${bill.title}';

        final expenseTx = TransactionModel(
          id: '',
          userId: currentUserId,
          title: txTitle,
          amount: settledShare.amount,
          type: TransactionType.expense,
          category: 'Split Bill',
          description: 'Settled group bill share',
          date: DateTime.now(),
        );

        await ref
            .read(transactionControllerProvider.notifier)
            .addTransaction(expenseTx);

        success = true;
      }
    });

    return success;
  }
}

/// Provider for [SocialController]
final socialControllerProvider =
    NotifierProvider<SocialController, AsyncValue<void>>(SocialController.new);
