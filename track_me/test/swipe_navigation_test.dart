import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:track_me/core/router/app_router.dart';
import 'package:track_me/core/shell/main_shell.dart';

void main() {
  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.dashboard,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(body: Center(child: Text('Dashboard Tab'))),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.habits,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(body: Center(child: Text('Habits Tab'))),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.cashflow,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(body: Center(child: Text('Cashflow Tab'))),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.goals,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(body: Center(child: Text('Goals Tab'))),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(body: Center(child: Text('Profile Tab'))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('swiping left moves forward across tabs: Dashboard -> Habits -> Cashflow -> Goals', (tester) async {
    final router = buildTestRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Tab'), findsOneWidget);

    // Swipe left (finger moves right to left: Offset(-200, 0)) -> Navigates to Habits
    await tester.drag(find.text('Dashboard Tab'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Habits Tab'), findsOneWidget);

    // Swipe left again -> Navigates to Cashflow
    await tester.drag(find.text('Habits Tab'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Cashflow Tab'), findsOneWidget);

    // Swipe left again -> Navigates to Goals
    await tester.drag(find.text('Cashflow Tab'), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Goals Tab'), findsOneWidget);

    // Swipe right (finger moves left to right: Offset(200, 0)) -> Navigates back to Cashflow
    await tester.drag(find.text('Goals Tab'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Cashflow Tab'), findsOneWidget);

    // Swipe right again -> Navigates back to Habits
    await tester.drag(find.text('Cashflow Tab'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Habits Tab'), findsOneWidget);

    // Swipe right again -> Navigates back to Dashboard
    await tester.drag(find.text('Habits Tab'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Tab'), findsOneWidget);
  });

  testWidgets('swiping right at leftmost tab and swiping left at rightmost tab do nothing', (tester) async {
    final router = buildTestRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Tab'), findsOneWidget);

    // Swiping right while on Dashboard should stay on Dashboard
    await tester.drag(find.text('Dashboard Tab'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Tab'), findsOneWidget);
  });
}
