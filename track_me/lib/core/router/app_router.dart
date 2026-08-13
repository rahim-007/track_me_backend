import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';

import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/expenses/presentation/screens/expense_setup_wizard.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/expenses/presentation/screens/expense_analytics_screen.dart';
import '../../features/expenses/presentation/screens/all_transactions_screen.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../shell/main_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _slideTransition,
        ),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RegisterScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // Main Shell (Bottom Nav)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.habits,
            name: 'habits',
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const HabitsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.goals,
            name: 'goals',
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const GoalsScreen(),
            ),
          ),

          GoRoute(
            path: AppRoutes.expenses,
            name: 'expenses',
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const ExpensesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Expense Setup (full-screen, outside shell)
      GoRoute(
        path: AppRoutes.expenseSetup,
        name: 'expense-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExpenseSetupWizard(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Expense Detail
      GoRoute(
        path: AppRoutes.expenseDetail,
        name: 'expense-detail',
        pageBuilder: (context, state) {
          final expense = state.extra as ExpenseModel;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ExpenseDetailScreen(expense: expense),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Expense Analytics
      GoRoute(
        path: AppRoutes.expenseAnalytics,
        name: 'expense-analytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExpenseAnalyticsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // All Transactions
      GoRoute(
        path: AppRoutes.allTransactions,
        name: 'all-transactions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AllTransactionsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

NoTransitionPage<void> _noTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    )),
    child: child,
  );
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/login/register';
  static const String forgotPassword = '/login/forgot-password';
  static const String dashboard = '/dashboard';
  static const String habits = '/habits';
  static const String goals = '/goals';

  static const String expenses = '/expenses';
  static const String expenseSetup = '/expense-setup';
  static const String expenseDetail = '/expense-detail';
  static const String expenseAnalytics = '/expense-analytics';
  static const String allTransactions = '/all-transactions';
  static const String profile = '/profile';
}
