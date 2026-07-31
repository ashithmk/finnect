/// Static, non-localized strings.
///
/// NOTE: This app is architected to move to `flutter_localizations` /
/// ARB-based i18n later. For now, all user-facing copy is centralized
/// here so that swap-in is mechanical rather than a search-and-replace
/// across feature files.
abstract class AppStrings {
  AppStrings._();

  static const String appName = 'Finnect';
  static const String tagline = 'Every rupee has a story.';

  // Auth
  static const String signIn = 'Log In';
  static const String signUp = 'Create Account';
  static const String signInWithGoogle = 'Continue with Google';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot password?';

  // Nav labels
  static const String navDashboard = 'Home';
  static const String navTransactions = 'History';
  static const String navAnalytics = 'Analytics';
  static const String navBudget = 'Budget';
  static const String navProfile = 'Profile';

  // Dashboard
  static const String totalBalance = 'Total Balance';
  static const String totalIncome = 'Income';
  static const String totalExpense = 'Expense';
  static const String budgetRemaining = 'Budget Remaining';
  static const String recentTransactions = 'Recent Transactions';
  static const String upcomingBills = 'Upcoming Bills';
  static const String seeAll = 'See all';

  // Transactions
  static const String addTransaction = 'Add Transaction';
  static const String editTransaction = 'Edit Transaction';
  static const String expense_ = 'Expense';
  static const String income_ = 'Income';
  static const String transfer_ = 'Transfer';
  static const String amount = 'Amount';
  static const String category = 'Category';
  static const String account = 'Account';
  static const String description = 'Description';
  static const String date = 'Date';
  static const String paymentMethod = 'Payment Method';
  static const String tags = 'Tags';
  static const String attachReceipt = 'Attach Receipt';
  static const String noTransactionsYet = 'No transactions yet';

  // Errors / empty states
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternet = 'You are offline. Changes will sync later.';
  static const String requiredField = 'This field is required';
  static const String invalidAmount = 'Enter a valid amount';
  static const String invalidEmail = 'Enter a valid email address';

  // Default currency
  static const String defaultCurrencyCode = 'INR';
  static const String defaultCurrencySymbol = '₹';
}

/// Default expense/income category seed data (name + icon key + type).
/// iconName strings map to `Icons.<name>` via a lookup table in
/// `core/widgets` — kept as plain strings so they're Firestore-serializable.
class DefaultCategory {
  final String name;
  final String iconName;
  final String type; // 'income' | 'expense'

  const DefaultCategory(this.name, this.iconName, this.type);
}

const List<DefaultCategory> kDefaultCategories = <DefaultCategory>[
  DefaultCategory('Food', 'restaurant', 'expense'),
  DefaultCategory('Travel', 'flight', 'expense'),
  DefaultCategory('Rent', 'home', 'expense'),
  DefaultCategory('Shopping', 'shopping_bag', 'expense'),
  DefaultCategory('Medical', 'local_hospital', 'expense'),
  DefaultCategory('Education', 'school', 'expense'),
  DefaultCategory('Entertainment', 'movie', 'expense'),
  DefaultCategory('Bills', 'receipt_long', 'expense'),
  DefaultCategory('Salary', 'work', 'income'),
  DefaultCategory('Investment', 'trending_up', 'income'),
  DefaultCategory('Gift', 'card_giftcard', 'income'),
  DefaultCategory('Others', 'category', 'expense'),
];
