import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold_shell.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import 'route_names.dart';

/// Root navigator key — lets non-shell routes still fully cover the screen above bottom nav.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Helper class to convert an authentication Stream into a [ChangeNotifier] for [GoRouter.refreshListenable].
/// Only notifies listeners when the logged-in status actually changes (logged in vs logged out).
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AppUser?> _subscription;
  bool? _lastIsLoggedIn;

  GoRouterRefreshStream(Stream<AppUser?> stream) {
    _subscription = stream.listen(
      (user) {
        final isLoggedIn = user != null;
        if (_lastIsLoggedIn != isLoggedIn) {
          _lastIsLoggedIn = isLoggedIn;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (hasListeners) {
              notifyListeners();
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the app's [GoRouter] with authentication redirect guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final matchedLoc = state.matchedLocation;
      if (matchedLoc == RouteNames.splash) {
        return null;
      }

      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;

      final isAuthRoute = matchedLoc == RouteNames.login ||
          matchedLoc == RouteNames.register;

      // If user is not logged in and trying to access protected routes, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      // If user is logged in and trying to access login or register screen, redirect to dashboard
      if (isLoggedIn && (matchedLoc == RouteNames.login || matchedLoc == RouteNames.register)) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.goals,
        builder: (context, state) => const GoalsScreen(),
      ),

      // Bottom-nav shell with 4 main branches: Home (0), Transactions (1), Analytics (2), Profile (3)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffoldShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),

          // Branch 1: Transactions
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.transactions,
              builder: (context, state) => const TransactionsScreen(),
            ),
          ]),

          // Branch 2: Analytics
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.analytics,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ]),

          // Branch 3: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
