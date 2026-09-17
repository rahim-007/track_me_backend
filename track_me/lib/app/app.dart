import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/home_widget_service.dart';
import '../features/cashflow/presentation/widgets/add_entry_sheet.dart';
import '../features/goals/data/models/goal_model.dart';
import '../features/goals/presentation/widgets/add_goal_dialog.dart';
import '../features/goals/providers/goals_provider.dart';
import '../features/habits/data/models/habit_model.dart';
import '../features/habits/providers/habits_provider.dart';

class TrackMeApp extends ConsumerStatefulWidget {
  const TrackMeApp({super.key});

  @override
  ConsumerState<TrackMeApp> createState() => _TrackMeAppState();
}

class _TrackMeAppState extends ConsumerState<TrackMeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initHomeWidget();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    await HomeWidgetService.instance.processPendingToggles(ref);
    await ref.read(habitsProvider.notifier).loadHabits();
  }

  Future<void> _initHomeWidget() async {
    await HomeWidgetService.instance.initialize(
      onUriReceived: (uri) => _handleWidgetUri(uri),
    );
    await HomeWidgetService.instance.processPendingToggles(ref);
  }

  void _handleWidgetUri(Uri uri) {
    if (uri.scheme != 'urday') return;

    final context = rootNavigatorKey.currentContext;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (host == 'habits' || path.contains('habits')) {
      final toggleId = uri.queryParameters['toggle'];
      if (toggleId != null && toggleId.isNotEmpty) {
        final alreadyHandled =
            HomeWidgetService.instance.isRecentlyHandled(toggleId);
        if (!alreadyHandled) {
          final habitsState = ref.read(habitsProvider);
          final habits = habitsState.valueOrNull ?? [];
          final habit = habits.firstWhere(
            (h) => h.id == toggleId,
            orElse: () => HabitModel(
              id: '',
              name: '',
              category: '',
              repeatDays: const [],
              createdAt: DateTime.now(),
              completedDates: const [],
              skippedDates: const [],
            ),
          );
          if (habit.id.isNotEmpty) {
            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final isCurrentlyCompleted =
                habit.completedDates.contains(todayStr);
            final completedParam = uri.queryParameters['completed'];
            final desiredCompleted = completedParam != null
                ? (completedParam == 'true' || completedParam == '1')
                : null;

            if (desiredCompleted == null ||
                isCurrentlyCompleted != desiredCompleted) {
              HomeWidgetService.instance.markHandled(toggleId);
              ref
                  .read(habitsProvider.notifier)
                  .toggleCompletion(habit, DateTime.now());
            }
          }
        }
      }
      if (context != null) {
        GoRouter.of(context).go(AppRoutes.habits);
      }
    } else if (host == 'dashboard' || path.contains('dashboard')) {
      if (context != null) {
        GoRouter.of(context).go(AppRoutes.dashboard);
      }
    } else if (host == 'cashflow' || path.contains('cashflow')) {
      if (context != null) {
        GoRouter.of(context).go(AppRoutes.cashflow);
        final action = uri.queryParameters['action']?.toLowerCase();
        if (action == 'income' || action == 'add_income') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentCtx = rootNavigatorKey.currentContext;
            if (currentCtx == null) return;
            AddEntrySheet.show(currentCtx, initialKindIndex: 0);
          });
        } else if (action == 'outflow' || action == 'add_outflow') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentCtx = rootNavigatorKey.currentContext;
            if (currentCtx == null) return;
            AddEntrySheet.show(currentCtx, initialKindIndex: 1);
          });
        }
      }
    } else if (host == 'goals' || path.contains('goals')) {
      if (context != null) {
        GoRouter.of(context).go(AppRoutes.goals);
        final action = uri.queryParameters['action'];
        final goalId = uri.queryParameters['id'];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentCtx = rootNavigatorKey.currentContext;
          if (currentCtx == null) return;

          if (action == 'add' || goalId == 'add') {
            showDialog(
              context: currentCtx,
              barrierDismissible: false,
              builder: (_) => const AddGoalDialog(),
            );
          } else if (goalId != null && goalId.isNotEmpty) {
            final goalsState = ref.read(goalsProvider);
            final goals = goalsState.valueOrNull ?? [];
            final goal = goals.firstWhere(
              (g) => g.id == goalId,
              orElse: () => GoalModel(
                id: '',
                name: '',
                category: '',
                targetDate: DateTime.now(),
                priority: 'Medium',
                status: 'in_progress',
                progress: 0.0,
                createdAt: DateTime.now(),
              ),
            );
            if (goal.id.isNotEmpty) {
              showDialog(
                context: currentCtx,
                barrierDismissible: false,
                builder: (_) => AddGoalDialog(goal: goal),
              );
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeProvider);

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: MaterialApp.router(
        key: ValueKey(isDarkMode),
        title: 'UrDay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
