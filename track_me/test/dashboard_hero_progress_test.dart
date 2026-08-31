import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/features/cashflow/providers/cashflow_provider.dart';
import 'package:track_me/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:track_me/features/goals/data/models/goal_model.dart';
import 'package:track_me/features/goals/providers/goals_provider.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';
import 'package:track_me/features/profile/providers/profile_provider.dart';

class _MockHabitsNotifier extends HabitsNotifier {
  _MockHabitsNotifier(List<HabitModel> initial) : super() {
    state = AsyncValue.data(initial);
  }
  @override
  Future<void> loadHabits() async {}
}

class _MockGoalsNotifier extends GoalsNotifier {
  _MockGoalsNotifier(List<GoalModel> initial) : super() {
    state = AsyncValue.data(initial);
  }
  @override
  Future<void> loadGoals() async {}
}

class _MockProfileNotifier extends ProfileNotifier {
  _MockProfileNotifier(UserProfile initial) : super() {
    state = AsyncValue.data(initial);
  }
  @override
  Future<void> loadProfile() async {}
}

class _MockCashFlowNotifier extends CashFlowNotifier {
  _MockCashFlowNotifier(CashFlowState initial) : super() {
    state = initial;
  }
  @override
  Future<void> loadCashFlow() async {}
}

void main() {
  testWidgets('Dashboard hero progress card displays weekly progress and completion metrics', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.weekday % 7;
    final weekStart = today.subtract(Duration(days: diff));

    final date1Str = DateFormat('yyyy-MM-dd').format(weekStart);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final habit1 = HabitModel(
      id: 'h1',
      name: 'Exercise',
      category: 'Fitness',
      repeatDays: List.filled(7, true),
      completedDates: [date1Str, todayStr],
      skippedDates: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    final profile = UserProfile(
      id: 'u1',
      name: 'Alex',
      email: 'alex@example.com',
      avatarUrl: null,
      currentStreak: 5,
      longestStreak: 10,
      totalCompletedHabits: 25,
      activeGoals: 2,
      createdAt: DateTime.now(),
      totalHabits: 1,
      goalsAchieved: 0,
    );

    const cashFlowState = CashFlowState();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier([habit1])),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(profile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(cashFlowState)),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly Progress'), findsOneWidget);
    expect(find.text('This Week'), findsWidgets);
    expect(find.textContaining('completed this week'), findsOneWidget);
  });

  testWidgets('Brand new user shows 0% Weekly Progress, 0.0 bar, 0 streak, 0 habits, 0 goals', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final newProfile = UserProfile(
      id: 'u_new',
      name: 'Newcomer',
      email: 'new@example.com',
      avatarUrl: null,
      currentStreak: 0,
      longestStreak: 0,
      totalCompletedHabits: 0,
      activeGoals: 0,
      createdAt: DateTime.now(),
      totalHabits: 0,
      goalsAchieved: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier([])),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(newProfile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Weekly Progress shows 0%
    expect(find.text('0%'), findsWidgets);
    // 2. Progress bar has value 0.0
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator).first);
    expect(indicator.value, 0.0);
    // 3. Subtitle shows 'Keep going! You\'re doing great.'
    expect(find.text("Keep going! You're doing great."), findsOneWidget);
    // 4. Arrow icon is completely removed from the Weekly Progress card
    final weeklyProgressCard = find.ancestor(of: find.text('Weekly Progress'), matching: find.byType(Container)).first;
    expect(find.descendant(of: weeklyProgressCard, matching: find.byIcon(Icons.north_east_rounded)), findsNothing);
    // 5. Metric counts are 0
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('1 completed out of 4 scheduled habits yields 25% Weekly Progress', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final weekdayIdx = today.weekday - 1;

    // Only scheduled for today
    List<bool> singleDayRepeat() {
      final list = List.filled(7, false);
      list[weekdayIdx] = true;
      return list;
    }

    final habits = [
      HabitModel(id: 'h1', name: 'H1', category: 'General', repeatDays: singleDayRepeat(), completedDates: [todayStr], skippedDates: const [], createdAt: now),
      HabitModel(id: 'h2', name: 'H2', category: 'General', repeatDays: singleDayRepeat(), completedDates: const [], skippedDates: const [], createdAt: now),
      HabitModel(id: 'h3', name: 'H3', category: 'General', repeatDays: singleDayRepeat(), completedDates: const [], skippedDates: const [], createdAt: now),
      HabitModel(id: 'h4', name: 'H4', category: 'General', repeatDays: singleDayRepeat(), completedDates: const [], skippedDates: const [], createdAt: now),
    ];

    final profile = UserProfile(id: 'u1', name: 'Alex', email: 'a@b.com', avatarUrl: null, currentStreak: 1, longestStreak: 1, totalCompletedHabits: 1, activeGoals: 0, createdAt: now, totalHabits: 4, goalsAchieved: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(profile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator).first);
    expect(indicator.value, 0.25);
    expect(find.text('1 of 4 completed this week'), findsOneWidget);
  });

  testWidgets('5 completed out of 5 scheduled habits yields 100% Weekly Progress', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final weekdayIdx = today.weekday - 1;

    List<bool> singleDayRepeat() {
      final list = List.filled(7, false);
      list[weekdayIdx] = true;
      return list;
    }

    final habits = List.generate(
      5,
      (i) => HabitModel(id: 'h$i', name: 'H$i', category: 'General', repeatDays: singleDayRepeat(), completedDates: [todayStr], skippedDates: const [], createdAt: now),
    );

    final profile = UserProfile(id: 'u1', name: 'Alex', email: 'a@b.com', avatarUrl: null, currentStreak: 5, longestStreak: 5, totalCompletedHabits: 5, activeGoals: 0, createdAt: now, totalHabits: 5, goalsAchieved: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(profile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator).first);
    expect(indicator.value, 1.0);
    expect(find.text('5 of 5 completed this week'), findsOneWidget);
  });

  testWidgets('No activity (0 completed out of 4 scheduled) yields 0% Weekly Progress', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekdayIdx = today.weekday - 1;

    List<bool> singleDayRepeat() {
      final list = List.filled(7, false);
      list[weekdayIdx] = true;
      return list;
    }

    final habits = List.generate(
      4,
      (i) => HabitModel(id: 'h$i', name: 'H$i', category: 'General', repeatDays: singleDayRepeat(), completedDates: const [], skippedDates: const [], createdAt: now),
    );

    final profile = UserProfile(id: 'u1', name: 'Alex', email: 'a@b.com', avatarUrl: null, currentStreak: 0, longestStreak: 0, totalCompletedHabits: 0, activeGoals: 0, createdAt: now, totalHabits: 4, goalsAchieved: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(profile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsWidgets);
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator).first);
    expect(indicator.value, 0.0);
    expect(find.text('0 of 4 completed this week'), findsOneWidget);
  });

  testWidgets('Cumulative Weekly Target: 2 completed out of 7 weekly scheduled habits yields 29% progress', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.weekday % 7;
    final weekStart = today.subtract(Duration(days: diff));

    final date1Str = DateFormat('yyyy-MM-dd').format(weekStart);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // 1 habit scheduled for all 7 days of the week
    final habits = [
      HabitModel(
        id: 'h1',
        name: 'Daily Reading',
        category: 'Personal Growth',
        repeatDays: List.filled(7, true),
        completedDates: [date1Str, todayStr],
        skippedDates: const [],
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];

    final profile = UserProfile(
      id: 'u1',
      name: 'Alex',
      email: 'a@b.com',
      avatarUrl: null,
      currentStreak: 2,
      longestStreak: 2,
      totalCompletedHabits: 2,
      activeGoals: 0,
      createdAt: now,
      totalHabits: 1,
      goalsAchieved: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
          goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
          profileProvider.overrideWith((ref) => _MockProfileNotifier(profile)),
          cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 2 completions out of 7 total weekly scheduled habits = 28.57% -> 29%
    // If today is Sunday (weekStart == today), date1Str == todayStr, so completions = 1 -> 14%
    final expectedCompletions = (weekStart == today) ? 1 : 2;
    final expectedPercent = ((expectedCompletions / 7) * 100).round();
    expect(find.text('$expectedPercent%'), findsOneWidget);
    expect(find.text('$expectedCompletions of 7 completed this week'), findsOneWidget);
  });

  test('calculateWeeklyHabitStats returns 11% and 2 of 19 for 2 completed out of 19 scheduled', () {
    final now = DateTime(2026, 8, 30); // Sunday
    // Create habits that total 19 scheduled occurrences in the week:
    // E.g. 2 daily habits (7 + 7 = 14) + 1 habit scheduled 5 days (5) = 19 scheduled occurrences
    final h1 = HabitModel(
      id: 'h1',
      name: 'H1',
      category: 'Fitness',
      repeatDays: List.filled(7, true), // 7
      completedDates: ['2026-08-30'], // 1
      skippedDates: const [],
      createdAt: DateTime(2026, 1, 1),
    );
    final h2 = HabitModel(
      id: 'h2',
      name: 'H2',
      category: 'Reading',
      repeatDays: List.filled(7, true), // 7
      completedDates: ['2026-08-30'], // 1
      skippedDates: const [],
      createdAt: DateTime(2026, 1, 1),
    );
    final h3 = HabitModel(
      id: 'h3',
      name: 'H3',
      category: 'Coding',
      repeatDays: const [true, true, true, true, true, false, false], // 5
      completedDates: const [], // 0
      skippedDates: const [],
      createdAt: DateTime(2026, 1, 1),
    );

    final stats = calculateWeeklyHabitStats([h1, h2, h3], now: now);
    expect(stats.scheduledCount, 19);
    expect(stats.completedCount, 2);
    expect(stats.percent, 11); // 2 / 19 * 100 = 10.526% -> 11%
  });
}
