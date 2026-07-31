import 'package:flutter_test/flutter_test.dart';
import 'package:finnect/features/transactions/domain/transaction_model.dart';
import 'package:finnect/features/transactions/data/transaction_repository.dart';

void main() {
  group('TransactionModel Serialization Tests', () {
    test('TransactionModel toMap and fromMap works correctly', () {
      final tx = TransactionModel(
        id: 'tx_001',
        userId: 'user_123',
        title: 'Lunch',
        amount: 350.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 7, 27),
        description: 'Office lunch',
      );

      final map = tx.toMap();
      expect(map['id'], 'tx_001');
      expect(map['title'], 'Lunch');
      expect(map['amount'], 350.0);
      expect(map['type'], 'expense');
      expect(map['category'], 'Food');

      final reconstructed = TransactionModel.fromMap(map);
      expect(reconstructed.id, tx.id);
      expect(reconstructed.title, tx.title);
      expect(reconstructed.amount, tx.amount);
      expect(reconstructed.type, tx.type);
      expect(reconstructed.category, tx.category);
    });
  });

  group('TransactionRepository Integration Tests', () {
    late LocalMockTransactionRepository repository;

    setUp(() {
      repository = LocalMockTransactionRepository(seedData: false);
    });

    test('addTransaction stores transaction and emits via stream', () async {
      final tx = TransactionModel(
        id: 'tx_1',
        userId: 'user_1',
        title: 'Salary',
        amount: 50000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime.now(),
      );

      await repository.addTransaction(tx);
      final streamList = await repository.getTransactions('user_1').first;
      expect(streamList.length, 1);
      expect(streamList.first.title, 'Salary');
      expect(streamList.first.amount, 50000.0);
    });

    test('deleteTransaction removes transaction from repository', () async {
      final tx = TransactionModel(
        id: 'tx_to_delete',
        userId: 'user_1',
        title: 'Coffee',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime.now(),
      );

      await repository.addTransaction(tx);
      await repository.deleteTransaction('user_1', 'tx_to_delete');

      final streamList = await repository.getTransactions('user_1').first;
      expect(streamList.isEmpty, isTrue);
    });
  });
}
