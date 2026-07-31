import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction_model.dart';

/// Contract for managing transactions in database.
abstract class TransactionRepository {
  /// Stream emitting real-time list of transactions for a user.
  Stream<List<TransactionModel>> getTransactions(String userId);

  /// Adds a new transaction document to the database.
  Future<void> addTransaction(TransactionModel transaction);

  /// Deletes a transaction from the database.
  Future<void> deleteTransaction(String userId, String transactionId);
}

/// Firebase Firestore implementation of [TransactionRepository].
class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;

  FirebaseTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userTransactionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  @override
  Stream<List<TransactionModel>> getTransactions(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _userTransactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final ref = _userTransactionsRef(transaction.userId);
    final docRef = transaction.id.isNotEmpty ? ref.doc(transaction.id) : ref.doc();
    final toSave = transaction.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap());
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _userTransactionsRef(userId).doc(transactionId).delete();
  }
}

/// Fallback Mock implementation of [TransactionRepository] with realistic dummy seed data.
class LocalMockTransactionRepository implements TransactionRepository {
  final StreamController<List<TransactionModel>> _controller =
      StreamController<List<TransactionModel>>.broadcast();
  final List<TransactionModel> _items = [];

  LocalMockTransactionRepository({bool seedData = true}) {
    if (seedData) {
      _seedDummyData();
    }
  }

  void _seedDummyData() {
    final now = DateTime.now();

    _items.addAll([
      // Today entries
      TransactionModel(
        id: 'tx_seed_1',
        userId: 'demo_user',
        title: 'Food',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now.subtract(const Duration(minutes: 45)),
      ),
      TransactionModel(
        id: 'tx_seed_2',
        userId: 'demo_user',
        title: 'Petrol',
        amount: 200.0,
        type: TransactionType.expense,
        category: 'Petrol',
        date: now.subtract(const Duration(hours: 3)),
      ),

      // Yesterday entries
      TransactionModel(
        id: 'tx_seed_3',
        userId: 'demo_user',
        title: 'Accessories',
        amount: 350.0,
        type: TransactionType.expense,
        category: 'Accessories',
        date: now.subtract(const Duration(days: 1, hours: 2)),
      ),

      // 3 Days ago entries (Lend - Money To Get)
      TransactionModel(
        id: 'tx_seed_4',
        userId: 'demo_user',
        title: 'Lend (Alex)',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Lend',
        description: 'Lent for emergency travel',
        date: now.subtract(const Duration(days: 3, hours: 4)),
      ),

      // 4 Days ago entries (Borrow - Money To Give)
      TransactionModel(
        id: 'tx_seed_borrow',
        userId: 'demo_user',
        title: 'Borrowed from Sam',
        amount: 300.0,
        type: TransactionType.income,
        category: 'Borrow',
        description: 'Borrowed for laptop adapter',
        date: now.subtract(const Duration(days: 4, hours: 2)),
      ),

      // 5 Days ago income & savings transfer entries
      TransactionModel(
        id: 'tx_seed_5',
        userId: 'demo_user',
        title: 'Salary',
        amount: 10000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: now.subtract(const Duration(days: 5, hours: 6)),
      ),
      TransactionModel(
        id: 'tx_seed_6',
        userId: 'demo_user',
        title: 'Transferred to Savings',
        amount: 2000.0,
        type: TransactionType.income,
        category: 'Savings',
        date: now.subtract(const Duration(days: 5, hours: 4)),
      ),

      // 8 Days ago entry (outside 7-day Recent filter, shows in History!)
      TransactionModel(
        id: 'tx_seed_7',
        userId: 'demo_user',
        title: 'Food',
        amount: 120.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now.subtract(const Duration(days: 8)),
      ),
    ]);
  }

  @override
  Stream<List<TransactionModel>> getTransactions(String userId) {
    Future.microtask(() => _controller.add(List.unmodifiable(_items)));
    return _controller.stream;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final newId = transaction.id.isNotEmpty
        ? transaction.id
        : 'tx_${DateTime.now().millisecondsSinceEpoch}';
    final saved = transaction.copyWith(id: newId);
    _items.insert(0, saved);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    _items.removeWhere((item) => item.id == transactionId);
    _controller.add(List.unmodifiable(_items));
  }
}
