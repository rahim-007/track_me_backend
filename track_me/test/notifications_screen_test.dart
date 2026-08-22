import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:track_me/features/notifications/data/models/notification_model.dart';
import 'package:track_me/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:track_me/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:track_me/features/notifications/providers/notifications_provider.dart';

NotificationModel make(
  String id, {
  required String title,
  NotificationCategory category = NotificationCategory.habit,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return NotificationModel(
    id: id,
    type: 'TYPE',
    title: title,
    message: 'Message for $title',
    isRead: isRead,
    createdAt: createdAt ?? DateTime.now(),
    category: category,
  );
}

class _FakeApi implements NotificationsApi {
  _FakeApi(this.items, {this.unreadCount = 0, this.failFetch = false});

  List<NotificationModel> items;
  int unreadCount;
  bool failFetch;
  final List<String> markedRead = [];
  int markAllCount = 0;
  final List<String> deleted = [];

  @override
  Future<List<NotificationModel>> fetch(int take, int skip) async {
    if (failFetch) throw Exception('network down');
    final start = skip < items.length ? skip : items.length;
    final end = (start + take) > items.length ? items.length : start + take;
    return items.sublist(start, end);
  }

  @override
  Future<int> fetchUnreadCount() async =>
      failFetch ? throw Exception('network down') : unreadCount;

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllRead() async {
    markAllCount++;
    unreadCount = 0;
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: NotificationBell()),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Habits Tab'))),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Goals Tab'))),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Expenses Tab'))),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Dashboard Tab'))),
      ),
    ],
  );
}

Future<void> pumpScreen(WidgetTester tester, _FakeApi api,
    {Size size = const Size(390, 844)}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsProvider
            .overrideWith((ref) => NotificationsNotifier(api: api)),
      ],
      child: MaterialApp.router(routerConfig: _buildRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders header, date sections, and notification cards',
      (tester) async {
    final now = DateTime.now();
    final api = _FakeApi(
      [
        make('a',
            title: 'Morning Run reminder',
            createdAt: now.subtract(const Duration(hours: 2))),
        make('b',
            title: 'Goal progress',
            category: NotificationCategory.goals,
            isRead: true,
            createdAt: now.subtract(const Duration(hours: 5))),
        make('c',
            title: 'Budget alert',
            category: NotificationCategory.cashflow,
            createdAt: now.subtract(const Duration(days: 1))),
        make('d',
            title: 'Weekly report ready',
            category: NotificationCategory.insights,
            isRead: true,
            createdAt: now.subtract(const Duration(days: 3))),
      ],
      unreadCount: 2,
    );
    await pumpScreen(tester, api);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Stay updated with your habits, goals, and progress.'),
        findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Morning Run reminder'), findsOneWidget);
    expect(find.text('Budget alert'), findsOneWidget);
    expect(find.text('Weekly report ready'), findsOneWidget);
    // Timestamps rendered for each section style.
    expect(find.textContaining('Today ·'), findsWidgets);
    expect(find.textContaining('Yesterday ·'), findsOneWidget);
  });

  testWidgets(
      'tapping an unread habit notification navigates to Habits and marks read',
      (tester) async {
    final api = _FakeApi(
      [make('a', title: 'Morning Run reminder')],
      unreadCount: 1,
    );
    await pumpScreen(tester, api);

    await tester.tap(find.text('Morning Run reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Habits Tab'), findsOneWidget);
    expect(api.markedRead, ['a']);
  });

  testWidgets('goals/cashflow/insights notifications navigate to their screens',
      (tester) async {
    final api = _FakeApi(
      [
        make('g', title: 'Goal complete', category: NotificationCategory.goals),
        make('c',
            title: 'Income added', category: NotificationCategory.cashflow),
        make('i',
            title: 'Insight ready', category: NotificationCategory.insights),
      ],
      unreadCount: 3,
    );
    await pumpScreen(tester, api);

    await tester.tap(find.text('Goal complete'));
    await tester.pumpAndSettle();
    expect(find.text('Goals Tab'), findsOneWidget);

    // Back to the notification center for the next tap.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider
              .overrideWith((ref) => NotificationsNotifier(api: api)),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Income added'));
    await tester.pumpAndSettle();
    expect(find.text('Expenses Tab'), findsOneWidget);
  });

  testWidgets('mark all as read clears unread state and disables the action',
      (tester) async {
    final api = _FakeApi(
      [make('a', title: 'One'), make('b', title: 'Two', isRead: true)],
      unreadCount: 1,
    );
    await pumpScreen(tester, api);

    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();

    expect(api.markAllCount, 1);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Mark all as read'),
    );
    expect(button.onPressed, isNull); // disabled when nothing unread
  });

  testWidgets('swiping a card deletes the notification', (tester) async {
    final api = _FakeApi(
      [make('a', title: 'Swipe me'), make('b', title: 'Keep me')],
      unreadCount: 2,
    );
    await pumpScreen(tester, api);

    await tester.drag(find.text('Swipe me'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(api.deleted, ['a']);
    expect(find.text('Swipe me'), findsNothing);
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no notifications',
      (tester) async {
    final api = _FakeApi([], unreadCount: 0);
    await pumpScreen(tester, api);

    expect(find.text("You're all caught up"), findsOneWidget);
    expect(
        find.textContaining('No new notifications right now.'), findsOneWidget);
  });

  testWidgets('shows the error state and recovers via Try again',
      (tester) async {
    final api = _FakeApi(
      [make('a', title: 'Recovered')],
      unreadCount: 1,
      failFetch: true,
    );
    await pumpScreen(tester, api);

    expect(find.text("Couldn't load notifications"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    api.failFetch = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text("Couldn't load notifications"), findsNothing);
  });

  testWidgets('renders without overflow on a small screen', (tester) async {
    final now = DateTime.now();
    final api = _FakeApi(
      [
        make('a',
            title: 'Morning Run reminder',
            createdAt: now.subtract(const Duration(hours: 1))),
        make('b',
            title: 'Goal progress',
            createdAt: now.subtract(const Duration(hours: 3))),
        make('c',
            title: 'Budget alert',
            createdAt: now.subtract(const Duration(days: 1))),
        make('d',
            title: 'Weekly report',
            createdAt: now.subtract(const Duration(days: 4))),
      ],
      unreadCount: 2,
    );
    await pumpScreen(tester, api, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
  });

  testWidgets('bell shows no badge at 0, a dot at 1, and a count above 1',
      (tester) async {
    Future<void> pumpBell(_FakeApi api) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider
                .overrideWith((ref) => NotificationsNotifier(api: api)),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: NotificationBell()),
                  ),
                ),
                GoRoute(
                  path: '/notifications',
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Tear down the tree between scenarios so a fresh ProviderScope (and
    // notifier) is created each time.
    Future<void> reset() async {
      await tester.pumpWidget(const SizedBox.shrink());
    }

    await pumpBell(_FakeApi([], unreadCount: 0));
    expect(find.byType(NotificationBell), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);

    await reset();
    await pumpBell(_FakeApi([make('a', title: 'x')], unreadCount: 1));
    expect(find.text('1'), findsNothing); // dot, not a number

    await reset();
    await pumpBell(_FakeApi(
      [make('a', title: 'x'), make('b', title: 'y'), make('c', title: 'z')],
      unreadCount: 3,
    ));
    expect(find.text('3'), findsOneWidget);
  });
}
