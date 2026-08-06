import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

/// Provider for [TransactionRepository]. Automatically detects Firebase.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseTransactionRepository();
  }
  return LocalMockTransactionRepository();
});

/// Stream provider of transactions for current user.
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.uid.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions(user.uid);
});

/// Computed summary data for dashboard including Net Total Balance, Savings, To Get (Lent), To Give (Borrowed), & 7-Day Recent Transactions.
class DashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double monthlyExpense;
  final double totalExpense;
  final double savings;
  final double toGet;
  final double toGive;
  final List<TransactionModel> recentTransactions;
  final List<TransactionModel> lendBorrowTransactions;

  const DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.monthlyExpense,
    required this.totalExpense,
    required this.savings,
    required this.toGet,
    required this.toGive,
    required this.recentTransactions,
    required this.lendBorrowTransactions,
  });
}

/// Provider computing financial summary metrics dynamically from database transactions.
final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final transactions = transactionsAsync.asData?.value ?? [];
  final now = DateTime.now();
  final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));

  double balanceIncome = 0.0;
  double savingsIncome = 0.0;
  double totalExpense = 0.0;
  double monthlyExpense = 0.0;
  double toGet = 0.0;
  double toGive = 0.0;
  final List<TransactionModel> lendBorrowList = [];

  for (final tx in transactions) {
    final catLower = tx.category.toLowerCase();

    // Check Lend (Money user lent out -> to get back)
    if (catLower == 'lend' || catLower == 'to get') {
      lendBorrowList.add(tx);
      if (!tx.isClosed) {
        toGet += tx.remainingAmount;
        balanceIncome += tx.repaidAmount;
      } else {
        balanceIncome += tx.amount;
      }
    }
    // Check Borrow (Money user borrowed -> to give back)
    else if (catLower == 'borrow' || catLower == 'to give') {
      lendBorrowList.add(tx);
      if (!tx.isClosed) {
        toGive += tx.remainingAmount;
        totalExpense += tx.repaidAmount;
      } else {
        totalExpense += tx.amount;
      }
    }

    if (tx.type == TransactionType.income) {
      if (catLower == 'savings') {
        savingsIncome += tx.amount;
      } else if (catLower != 'borrow' && catLower != 'to give') {
        balanceIncome += tx.amount;
      }
    } else if (tx.type == TransactionType.expense) {
      if (catLower != 'lend' && catLower != 'to get') {
        totalExpense += tx.amount;
        if (tx.date.month == now.month && tx.date.year == now.year) {
          monthlyExpense += tx.amount;
        }
      } else {
        // Original Lend principal count in total expense
        totalExpense += tx.amount;
      }
    }
  }

  // Net Total Balance = Total Income - Total Expense
  final netBalance = balanceIncome - totalExpense;
  final availableTotalBalance = netBalance;

  // Total Savings = Accumulated Savings
  final totalSavings = savingsIncome < 0 ? 0.0 : savingsIncome;

  // Filter recent transactions to the past 7 days (within a week)
  final recentSevenDays = transactions
      .where((tx) => tx.date.isAfter(sevenDaysAgo))
      .toList();

  return DashboardSummary(
    totalBalance: availableTotalBalance,
    totalIncome: balanceIncome,
    monthlyExpense: monthlyExpense,
    totalExpense: totalExpense,
    savings: totalSavings,
    toGet: toGet,
    toGive: toGive,
    recentTransactions: recentSevenDays,
    lendBorrowTransactions: lendBorrowList,
  );
});

/// Controller for executing transaction creation, modification, and deletion.
class TransactionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addTransaction(transaction);
    });
    return !state.hasError;
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    final repository = ref.read(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateTransaction(transaction);
    });
    return !state.hasError;
  }

  Future<bool> deleteTransaction(String transactionId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    final repository = ref.read(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTransaction(user.uid, transactionId);
    });
    return !state.hasError;
  }
}

/// Provider for [TransactionController].
final transactionControllerProvider =
    NotifierProvider<TransactionController, AsyncValue<void>>(
        TransactionController.new);
