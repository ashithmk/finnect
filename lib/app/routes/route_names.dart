/// Centralized route paths and names for GoRouter.
///
/// Keeping paths as constants avoids typo-driven navigation bugs and makes
/// it trivial to grep for every place a given screen is pushed from.
abstract class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Shell (bottom nav) branches
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String analytics = '/analytics';
  static const String budget = '/budget';
  static const String profile = '/profile';

  // Transactions
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/edit'; // :id
  static const String transactionDetail = '/transactions/detail'; // :id

  // Accounts
  static const String accounts = '/accounts';
  static const String addAccount = '/accounts/add';

  // Categories
  static const String categories = '/categories';
  static const String addCategory = '/categories/add';

  // Budget / Goals
  static const String addBudget = '/budget/add';
  static const String goals = '/goals';
  static const String addGoal = '/goals/add';
  static const String goalDetail = '/goals/detail'; // :id

  // Calendar / Recurring / Receipts / Reports
  static const String calendar = '/calendar';
  static const String recurring = '/recurring';
  static const String addRecurring = '/recurring/add';
  static const String receipts = '/receipts';
  static const String reports = '/reports';

  // Profile
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
}
