import 'package:flutter_test/flutter_test.dart';
import 'package:finnect/features/auth/domain/user_model.dart';
import 'package:finnect/features/social/data/social_repository.dart';
import 'package:finnect/features/social/domain/social_models.dart';
import 'package:finnect/features/transactions/data/transaction_repository.dart';
import 'package:finnect/features/transactions/domain/transaction_model.dart';

void main() {
  group('Unique Username tests', () {
    test('Formats username with @ prefix automatically', () {
      final user1 = AppUser(
        uid: 'u123',
        email: 'alex.smith@example.com',
        displayName: 'Alex Smith',
        username: 'alex_smith',
        createdAt: DateTime.now(),
      );

      expect(user1.formattedUsername, '@alex_smith');
    });

    test('Derives username from email if empty', () {
      final user2 = AppUser.fromMap({
        'uid': 'u456',
        'email': 'john_doe@example.com',
        'displayName': 'John',
      });

      expect(user2.username, 'john_doe');
      expect(user2.formattedUsername, '@john_doe');
    });
  });

  group('Social & Group Bill Splitting tests', () {
    late LocalMockSocialRepository socialRepo;
    late LocalMockTransactionRepository txRepo;

    setUp(() {
      socialRepo = LocalMockSocialRepository();
      txRepo = LocalMockTransactionRepository(seedData: false);
    });

    test('Search users by username', () async {
      final results = await socialRepo.searchUsers('demo_uid_1', 'alex');
      expect(results.isNotEmpty, true);
      expect(results.first.username, 'alex_m');
    });

    test('Send and accept friend request flow', () async {
      // Send request from demo_uid_1 to user_rohit
      await socialRepo.sendFriendRequest('demo_uid_1', 'user_rohit');

      // Check pending requests for user_rohit
      final pending = await socialRepo.getPendingFriendRequests('user_rohit').first;
      expect(pending.any((u) => u.uid == 'demo_uid_1'), true);

      // Accept request by user_rohit
      await socialRepo.acceptFriendRequest('user_rohit', 'demo_uid_1');

      // Verify both are now in each other's friends list
      final friends1 = await socialRepo.getFriends('demo_uid_1').first;
      final friends2 = await socialRepo.getFriends('user_rohit').first;

      expect(friends1.any((f) => f.uid == 'user_rohit'), true);
      expect(friends2.any((f) => f.uid == 'demo_uid_1'), true);
    });

    test('Create group with friends', () async {
      final group = GroupModel(
        id: '',
        name: 'Road Trip',
        description: 'Weekend trip',
        createdBy: 'demo_uid_1',
        memberIds: ['demo_uid_1', 'user_alex'],
        createdAt: DateTime.now(),
      );

      final created = await socialRepo.createGroup(group);
      expect(created.id.isNotEmpty, true);
      expect(created.name, 'Road Trip');
    });

    test('Split bill and settle share reduces balance & adds expense', () async {
      // 1. Create group
      final group = await socialRepo.createGroup(
        GroupModel(
          id: 'grp_test',
          name: 'Dinner Group',
          createdBy: 'user_alex',
          memberIds: ['demo_uid_1', 'user_alex'],
          createdAt: DateTime.now(),
        ),
      );

      // 2. Add split bill of ₹1000 (₹500 per member)
      final bill = GroupBillModel(
        id: 'bill_test',
        groupId: group.id,
        title: 'Sushi Dinner',
        totalAmount: 1000.0,
        paidByUserId: 'user_alex',
        shares: const [
          GroupBillShare(userId: 'demo_uid_1', amount: 500.0, isSettled: false),
          GroupBillShare(userId: 'user_alex', amount: 500.0, isSettled: true),
        ],
        createdAt: DateTime.now(),
      );

      await socialRepo.addBillToGroup(bill);

      // 3. Settle share for demo_uid_1
      final settledShare = await socialRepo.settleBillShare(
        groupId: group.id,
        billId: bill.id,
        userId: 'demo_uid_1',
      );

      expect(settledShare, isNotNull);
      expect(settledShare!.isSettled, true);
      expect(settledShare.amount, 500.0);

      // 4. Record expense transaction
      final expenseTx = TransactionModel(
        id: '',
        userId: 'demo_uid_1',
        title: '${group.name}: ${bill.title}',
        amount: settledShare.amount,
        type: TransactionType.expense,
        category: 'Split Bill',
        date: DateTime.now(),
      );

      await txRepo.addTransaction(expenseTx);

      // Verify transaction saved
      final stream = txRepo.getTransactions('demo_uid_1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.title, 'Dinner Group: Sushi Dinner');
      expect(list.first.amount, 500.0);
      expect(list.first.type, TransactionType.expense);
    });
  });
}
