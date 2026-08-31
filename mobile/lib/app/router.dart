import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/lock_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pin_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/more/more_screen.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/transactions_list_screen.dart';
import 'app_shell.dart';

const _authRoutes = ['/login', '/pin-setup', '/lock'];

final routerProvider = Provider<GoRouter>((ref) {
  final authPhase = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final location = state.matchedLocation;
      switch (authPhase) {
        case AuthPhase.loading:
          return null;
        case AuthPhase.loggedOut:
          return location == '/login' ? null : '/login';
        case AuthPhase.needsPinSetup:
          return location == '/pin-setup' ? null : '/pin-setup';
        case AuthPhase.locked:
          return location == '/lock' ? null : '/lock';
        case AuthPhase.unlocked:
          return _authRoutes.contains(location) ? '/home' : null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      // Halaman penuh, di luar shell (sesuai DESIGN.md — bukan nested tab).
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) =>
            TransactionFormScreen(transactionId: state.pathParameters['id']),
      ),
    ],
  );
});
