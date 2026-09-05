import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/more/more_screen.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/transactions_list_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authPhase = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/home',
    // Login OPSIONAL (plan: pakai app tanpa login dulu, local-first). Ga ada
    // paksa redirect ke /login — dia cuma route biasa yg dibuka dari More.
    // Satu-satunya redirect: kalau udah login terus buka /login lagi (mis.
    // abis sukses submit), balikin ke /home.
    redirect: (context, state) {
      if (authPhase == AuthPhase.unlocked && state.matchedLocation == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
