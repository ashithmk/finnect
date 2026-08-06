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

  // Goals
  static const String goals = '/goals';
  static const String addGoal = '/goals/add';
  static const String goalDetail = '/goals/detail'; // :id

  // Budget
  static const String addBudget = '/budget/add';

  // Profile
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
}
