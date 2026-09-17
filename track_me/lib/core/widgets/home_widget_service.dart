import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../features/cashflow/data/models/cashflow_models.dart';
import '../../features/goals/data/models/goal_model.dart';
import '../../features/goals/data/models/goal_units.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/data/quotes_data.dart';
import '../../features/habits/providers/habits_provider.dart';
import '../local/json_file_cache.dart';
import '../network/dio_client.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_queue.dart';
import '../theme/app_colors.dart';

/// Top-level background interactivity callback invoked when an interactive
/// widget button (such as habit tick) is tapped without launching the full app.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri == null) return;
  final toggleId = uri.queryParameters['toggle'] ?? uri.queryParameters['id'];
  final completedParam = uri.queryParameters['completed'];
  final desiredCompleted = completedParam != null
      ? (completedParam == 'true' || completedParam == '1')
      : null;
  if (toggleId != null && toggleId.isNotEmpty) {
    await HomeWidgetService.instance.handleBackgroundToggle(
      toggleId,
      desiredCompleted: desiredCompleted,
    );
  }
}

/// Centralized service connecting UrDay's state to Android & iOS Home Screen Widgets.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String appGroupId = 'group.com.trackme.app';
  static const String androidProgressWidget = 'UrDayProgressWidgetProvider';
  static const String androidHabitsWidget = 'UrDayHabitsWidgetProvider';
  static const String androidGoalWidget = 'UrDayGoalWidgetProvider';
  static const String androidCashFlowWidget = 'UrDayCashFlowWidgetProvider';
  static const String iOSProgressWidget = 'UrDayProgressWidget';
  static const String iOSHabitsWidget = 'UrDayHabitsWidget';
  static const String iOSGoalWidget = 'UrDayGoalWidget';
  static const String iOSCashFlowWidget = 'UrDayCashFlowWidget';

  static String? _consumedInitialUri;
  final Map<String, DateTime> _recentlyHandledToggles = {};

  bool isRecentlyHandled(String habitId) {
    final last = _recentlyHandledToggles[habitId];
    if (last == null) return false;
    return DateTime.now().difference(last).inSeconds < 5;
  }

  void markHandled(String habitId) {
    _recentlyHandledToggles[habitId] = DateTime.now();
  }

  Function(Uri uri)? _onUriCallback;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  /// Initialize HomeWidget listeners for handling taps from widgets.
  Future<void> initialize({Function(Uri uri)? onUriReceived}) async {
    _onUriCallback = onUriReceived;

    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.registerInteractivityCallback(
          homeWidgetBackgroundCallback);

      // Ensure initial default widget data is written if not already present
      final existingRatio =
          await HomeWidget.getWidgetData<String>('progress_ratio');
      if (existingRatio == null) {
        await HomeWidget.saveWidgetData<int>('progress_percent', 0);
        await HomeWidget.saveWidgetData<String>('progress_ratio', '0/0');
        await HomeWidget.saveWidgetData<int>('streak_count', 0);
        await HomeWidget.saveWidgetData<int>('base_streak_count', 0);
        await HomeWidget.saveWidgetData<String>(
            'daily_quote', 'Small healthy choices become a strong life.');
        await HomeWidget.saveWidgetData<String>('habits_json', '[]');
        await HomeWidget.saveWidgetData<String>('last_updated', 'Today');
        final now = DateTime.now();
        await HomeWidget.saveWidgetData<String>(
            'date_day_name', DateFormat('EEE').format(now));
        await HomeWidget.saveWidgetData<String>(
            'date_formatted', DateFormat('MMM d').format(now));
        await HomeWidget.saveWidgetData<bool>(
            'app_is_dark_mode', AppColors.isDarkMode);
        await HomeWidget.updateWidget(
            name: androidProgressWidget,
            androidName: androidProgressWidget,
            iOSName: iOSProgressWidget);
        await HomeWidget.updateWidget(
            name: androidHabitsWidget,
            androidName: androidHabitsWidget,
            iOSName: iOSHabitsWidget);
      }

      // Ensure goal widget is initialized or synchronized from cache
      final existingGoal = await HomeWidget.getWidgetData<String>('goal_name');
      if (existingGoal == null) {
        final cachedGoals = await JsonFileCache.read<List<GoalModel>>(
          'goals_cache',
          (json) => (json as List)
              .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        if (cachedGoals != null && cachedGoals.isNotEmpty) {
          await syncGoalsData(goals: cachedGoals);
        } else {
          await HomeWidget.saveWidgetData<bool>('has_active_goal', false);
          await HomeWidget.saveWidgetData<String>('goal_name', '');
          await HomeWidget.updateWidget(
            name: androidGoalWidget,
            androidName: androidGoalWidget,
            iOSName: iOSGoalWidget,
          );
        }
      }

      // Ensure cashflow widget is initialized or synchronized from cache
      final existingCashFlow =
          await HomeWidget.getWidgetData<String>('cashflow_net');
      if (existingCashFlow == null) {
        final cachedCashFlow = await JsonFileCache.read<Map<String, dynamic>>(
          'cashflow_cache',
          (json) => json as Map<String, dynamic>,
        );
        if (cachedCashFlow != null && cachedCashFlow['current'] != null) {
          final period = CashFlowPeriodModel.fromJson(
            Map<String, dynamic>.from(cachedCashFlow['current'] as Map),
            isCurrent: true,
          );
          await syncCashFlowData(period: period);
        } else {
          await HomeWidget.saveWidgetData<String>('cashflow_net', '+₹0');
          await HomeWidget.saveWidgetData<double>('cashflow_net_val', 0.0);
          await HomeWidget.saveWidgetData<bool>('cashflow_is_positive', true);
          await HomeWidget.saveWidgetData<String>('cashflow_income', '₹0');
          await HomeWidget.saveWidgetData<double>('cashflow_income_val', 0.0);
          await HomeWidget.saveWidgetData<String>('cashflow_outflow', '₹0');
          await HomeWidget.saveWidgetData<double>('cashflow_outflow_val', 0.0);
          await HomeWidget.saveWidgetData<String>('cashflow_bank', '₹0');
          await HomeWidget.saveWidgetData<String>('cashflow_cash', '₹0');
          await HomeWidget.saveWidgetData<String>('cashflow_card', '₹0');
          await HomeWidget.saveWidgetData<bool>('cashflow_has_data', false);
          final now = DateTime.now();
          await HomeWidget.saveWidgetData<String>(
            'cashflow_period_name',
            '${CashFlowPeriodModel.monthName(now.month)} ${now.year}',
          );
          await HomeWidget.updateWidget(
            name: androidCashFlowWidget,
            androidName: androidCashFlowWidget,
            iOSName: iOSCashFlowWidget,
          );
        }
      }

      // Check if the app was launched by tapping a widget (deduplicated per session)
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null && initialUri.toString() != _consumedInitialUri) {
        _consumedInitialUri = initialUri.toString();
        debugPrint('[HomeWidget] Launched with initial URI: $initialUri');
        _handleUri(initialUri);
      }

      // Listen for taps while the app is running in background/foreground
      _widgetClickSubscription?.cancel();
      _widgetClickSubscription = HomeWidget.widgetClicked.listen(
        (Uri? uri) {
          if (uri != null) {
            debugPrint('[HomeWidget] Widget clicked with URI: $uri');
            _handleUri(uri);
          }
        },
        onError: (err) {
          debugPrint('[HomeWidget] Error listening to widget clicks: $err');
        },
      );
    } catch (e) {
      debugPrint('[HomeWidget] Init skipped or failed: $e');
    }
  }

  void _handleUri(Uri uri) {
    _onUriCallback?.call(uri);
  }

  /// Sync habits, streak, and daily progress to the native widget storage.
  Future<void> syncHabitsData({
    required List<HabitModel> habits,
    required int overallStreak,
  }) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final weekdayIndex = now.weekday - 1; // 0 = Mon, 6 = Sun

      // Filter habits scheduled for today
      final todayHabits = habits.where((h) {
        final hasRepeatDays = h.repeatDays.any((d) => d);
        if (!hasRepeatDays) return true; // Daily if no days selected
        return weekdayIndex < h.repeatDays.length && h.repeatDays[weekdayIndex];
      }).toList();

      final totalCount = todayHabits.length;
      final completedCount =
          todayHabits.where((h) => h.completedDates.contains(todayStr)).length;
      final percent =
          totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

      // Select daily rotating motivational quote
      final quoteIndex =
          now.day % (kHabitQuotes.isNotEmpty ? kHabitQuotes.length : 1);
      final quote = kHabitQuotes.isNotEmpty
          ? kHabitQuotes[quoteIndex].quote
          : "Small healthy choices become a strong life.";
      final quoteAuthor =
          kHabitQuotes.isNotEmpty ? kHabitQuotes[quoteIndex].author : "UrDay";

      // Prepare habit items for the widget list (up to 10 items)
      // Prioritize habits scheduled for today. If fewer than 5 are scheduled today,
      // include the user's other active habits so all 5 compact widget slots can be populated.
      final otherHabits =
          habits.where((h) => !todayHabits.contains(h)).toList();
      final allDisplayHabits = [...todayHabits, ...otherHabits];

      final habitItems = allDisplayHabits.take(10).map((h) {
        final isCompleted = h.completedDates.contains(todayStr);
        final rawEmoji = h.emoji?.trim();
        final safeEmoji =
            (rawEmoji != null && rawEmoji.isNotEmpty && rawEmoji != 'null')
                ? rawEmoji
                : '⚡';
        final habitStreak = calculateHabitStreak(h);
        return {
          'id': h.id,
          'name': h.name,
          'category': h.category,
          'emoji': safeEmoji,
          'is_completed': isCompleted,
          'streak': habitStreak,
        };
      }).toList();

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStreak = calculateCurrentStreak(habits, from: yesterday);

      // Write values to widget storage
      await HomeWidget.saveWidgetData<int>('progress_percent', percent);
      await HomeWidget.saveWidgetData<String>(
        'progress_ratio',
        '$completedCount/$totalCount',
      );
      await HomeWidget.saveWidgetData<int>('completed_count', completedCount);
      await HomeWidget.saveWidgetData<int>('total_count', totalCount);
      await HomeWidget.saveWidgetData<int>('streak_count', overallStreak);
      await HomeWidget.saveWidgetData<int>('base_streak_count', yesterdayStreak);
      await HomeWidget.saveWidgetData<String>('daily_quote', quote);
      await HomeWidget.saveWidgetData<String>(
          'daily_quote_author', quoteAuthor);
      await HomeWidget.saveWidgetData<String>(
        'habits_json',
        jsonEncode(habitItems),
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateFormat('hh:mm a').format(now),
      );
      await HomeWidget.saveWidgetData<String>(
        'date_day_name',
        DateFormat('EEE').format(now),
      );
      await HomeWidget.saveWidgetData<String>(
        'date_formatted',
        DateFormat('MMM d').format(now),
      );
      await HomeWidget.saveWidgetData<bool>(
        'app_is_dark_mode',
        AppColors.isDarkMode,
      );

      // Trigger update on native side
      await HomeWidget.updateWidget(
        name: androidProgressWidget,
        androidName: androidProgressWidget,
        iOSName: iOSProgressWidget,
      );

      await HomeWidget.updateWidget(
        name: androidHabitsWidget,
        androidName: androidHabitsWidget,
        iOSName: iOSHabitsWidget,
      );

      debugPrint(
          '[HomeWidget] Successfully synchronized widget data: $completedCount/$totalCount ($percent%)');
    } catch (e) {
      debugPrint('[HomeWidget] Failed to sync widget data: $e');
    }
  }

  static String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return '🏃';
      case 'health':
        return '❤️';
      case 'career':
        return '💼';
      case 'finance':
        return '💰';
      case 'education':
        return '📚';
      case 'relationships':
        return '🤝';
      case 'personal':
        return '🎯';
      default:
        return '🎯';
    }
  }

  /// Synchronizes the primary active focus goal to the Hero Focus Goal widget.
  Future<void> syncGoalsData({required List<GoalModel> goals}) async {
    try {
      final activeGoals = goals.where((g) {
        final s = g.status.toLowerCase();
        return s != 'completed' && s != 'archived' && s != 'cancelled';
      }).toList();

      if (activeGoals.isEmpty) {
        await HomeWidget.saveWidgetData<bool>('has_active_goal', false);
        await HomeWidget.saveWidgetData<String>('goal_name', '');
        await HomeWidget.updateWidget(
          name: androidGoalWidget,
          androidName: androidGoalWidget,
          iOSName: iOSGoalWidget,
        );
        debugPrint(
            '[HomeWidget] No active goals found. Set goal widget to empty state.');
        return;
      }

      int priorityScore(String p) {
        switch (p.toUpperCase()) {
          case 'HIGH':
            return 3;
          case 'MEDIUM':
            return 2;
          case 'LOW':
            return 1;
          default:
            return 2;
        }
      }

      activeGoals.sort((a, b) {
        final pDiff =
            priorityScore(b.priority).compareTo(priorityScore(a.priority));
        if (pDiff != 0) return pDiff;
        return a.targetDate.compareTo(b.targetDate);
      });

      final goalItems = activeGoals.map((g) {
        final percent = (g.progress * 100).round().clamp(0, 100);
        String currentStr;
        String targetStr;
        if (g.hasTarget) {
          final currentNum = g.target * g.progress;
          currentStr = formatGoalValue(currentNum);
          targetStr = formatGoalValue(g.target);
        } else {
          currentStr = '$percent';
          targetStr = '100';
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(
          g.targetDate.year,
          g.targetDate.month,
          g.targetDate.day,
        );
        final daysRemaining = targetDay.difference(today).inDays;

        String urgencyTier;
        String urgencyText;

        if (daysRemaining > 30) {
          urgencyTier = 'green';
          urgencyText = '30+ days left';
        } else if (daysRemaining >= 7 && daysRemaining <= 14) {
          urgencyTier = 'amber';
          urgencyText = '⏳ $daysRemaining days left';
        } else if (daysRemaining > 14 && daysRemaining <= 30) {
          urgencyTier = 'green';
          urgencyText = '$daysRemaining days left';
        } else if (daysRemaining >= 1 && daysRemaining < 7) {
          urgencyTier = 'red';
          urgencyText =
              '🔥 $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left';
        } else if (daysRemaining == 0) {
          urgencyTier = 'red';
          urgencyText = '🔥 Due Today!';
        } else {
          urgencyTier = 'red';
          urgencyText = '⚠️ Overdue (${daysRemaining.abs()}d)';
        }

        final categoryIcon = _getCategoryEmoji(g.category);

        return {
          'id': g.id,
          'name': g.name,
          'progress_percent': percent,
          'current': currentStr,
          'target': targetStr,
          'unit': g.unit,
          'category': g.category,
          'category_icon': categoryIcon,
          'days_left': daysRemaining,
          'urgency_tier': urgencyTier,
          'urgency_text': urgencyText,
        };
      }).toList();

      int selectedIndex =
          await HomeWidget.getWidgetData<int>('selected_goal_index') ?? 0;
      if (selectedIndex < 0 || selectedIndex >= goalItems.length) {
        selectedIndex = 0;
      }
      final focusGoal = goalItems[selectedIndex];

      await HomeWidget.saveWidgetData<bool>('has_active_goal', true);
      await HomeWidget.saveWidgetData<String>(
          'goals_json', jsonEncode(goalItems));
      await HomeWidget.saveWidgetData<int>(
          'total_goals_count', goalItems.length);
      await HomeWidget.saveWidgetData<int>(
          'selected_goal_index', selectedIndex);

      await HomeWidget.saveWidgetData<String>(
          'goal_id', focusGoal['id'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_name', focusGoal['name'] as String);
      await HomeWidget.saveWidgetData<int>(
          'goal_progress_percent', focusGoal['progress_percent'] as int);
      await HomeWidget.saveWidgetData<String>(
          'goal_current', focusGoal['current'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_target', focusGoal['target'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_unit', focusGoal['unit'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_category', focusGoal['category'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_category_icon', focusGoal['category_icon'] as String);
      await HomeWidget.saveWidgetData<int>(
          'goal_days_left', focusGoal['days_left'] as int);
      await HomeWidget.saveWidgetData<String>(
          'goal_urgency_tier', focusGoal['urgency_tier'] as String);
      await HomeWidget.saveWidgetData<String>(
          'goal_urgency_text', focusGoal['urgency_text'] as String);

      await HomeWidget.updateWidget(
        name: androidGoalWidget,
        androidName: androidGoalWidget,
        iOSName: iOSGoalWidget,
      );

      debugPrint(
        '[HomeWidget] Synchronized Hero Focus Goal: "${focusGoal['name']}" index $selectedIndex of ${goalItems.length}',
      );
    } catch (e) {
      debugPrint('[HomeWidget] Failed to sync goal data: $e');
    }
  }

  /// Synchronizes the monthly Cash Flow period summary to the Cash Flow widget.
  Future<void> syncCashFlowData({required CashFlowPeriodModel period}) async {
    try {
      final net = period.netCashFlow;
      final isPositive = net >= 0;
      final currencyFormatter = NumberFormat('#,##0');

      final formattedNet =
          '${isPositive ? '+' : '-'}₹${currencyFormatter.format(net.abs().round())}';
      final formattedIncome = '₹${currencyFormatter.format(period.totalIncome.round())}';
      final formattedOutflow = '₹${currencyFormatter.format(period.totalOutflow.round())}';
      final formattedBank = '₹${currencyFormatter.format(period.closingBank.round())}';
      final formattedCash = '₹${currencyFormatter.format(period.closingCash.round())}';
      final formattedCard = '₹${currencyFormatter.format(period.closingCreditCard.round())}';

      final hasData = period.hasActivity ||
          period.totalIncome > 0 ||
          period.totalOutflow > 0 ||
          period.closingBank != 0 ||
          period.closingCash != 0 ||
          period.closingCreditCard != 0;

      await HomeWidget.saveWidgetData<String>('cashflow_net', formattedNet);
      await HomeWidget.saveWidgetData<double>('cashflow_net_val', net);
      await HomeWidget.saveWidgetData<bool>('cashflow_is_positive', isPositive);
      await HomeWidget.saveWidgetData<String>('cashflow_income', formattedIncome);
      await HomeWidget.saveWidgetData<double>(
          'cashflow_income_val', period.totalIncome);
      await HomeWidget.saveWidgetData<String>('cashflow_outflow', formattedOutflow);
      await HomeWidget.saveWidgetData<double>(
          'cashflow_outflow_val', period.totalOutflow);
      await HomeWidget.saveWidgetData<String>('cashflow_bank', formattedBank);
      await HomeWidget.saveWidgetData<String>('cashflow_cash', formattedCash);
      await HomeWidget.saveWidgetData<String>('cashflow_card', formattedCard);
      await HomeWidget.saveWidgetData<bool>('cashflow_has_data', hasData);
      await HomeWidget.saveWidgetData<String>('cashflow_period_name', period.label);
      await HomeWidget.saveWidgetData<bool>(
          'app_is_dark_mode', AppColors.isDarkMode);

      await HomeWidget.updateWidget(
        name: androidCashFlowWidget,
        androidName: androidCashFlowWidget,
        iOSName: iOSCashFlowWidget,
      );

      debugPrint(
        '[HomeWidget] Successfully synchronized Cash Flow widget: Net $formattedNet (Income: $formattedIncome, Outflow: $formattedOutflow)',
      );
    } catch (e) {
      debugPrint('[HomeWidget] Failed to sync Cash Flow widget data: $e');
    }
  }

  /// Synchronize user theme change directly to home screen widgets.
  Future<void> syncTheme({required bool isDarkMode}) async {
    try {
      await HomeWidget.saveWidgetData<bool>('app_is_dark_mode', isDarkMode);
      await HomeWidget.updateWidget(
        name: androidProgressWidget,
        androidName: androidProgressWidget,
        iOSName: iOSProgressWidget,
      );
      await HomeWidget.updateWidget(
        name: androidHabitsWidget,
        androidName: androidHabitsWidget,
        iOSName: iOSHabitsWidget,
      );
      await HomeWidget.updateWidget(
        name: androidGoalWidget,
        androidName: androidGoalWidget,
        iOSName: iOSGoalWidget,
      );
      await HomeWidget.updateWidget(
        name: androidCashFlowWidget,
        androidName: androidCashFlowWidget,
        iOSName: iOSCashFlowWidget,
      );
      debugPrint(
          '[HomeWidget] Successfully synchronized theme mode: isDarkMode=$isDarkMode');
    } catch (e) {
      debugPrint('[HomeWidget] Failed to sync theme: $e');
    }
  }

  /// Handles in-place habit toggling when triggered in the background
  Future<void> handleBackgroundToggle(
    String habitId, {
    bool? desiredCompleted,
  }) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final cachedHabits = await JsonFileCache.read<List<HabitModel>>(
        'habits_cache',
        (json) => (json as List)
            .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (cachedHabits == null || cachedHabits.isEmpty) return;

      HabitModel? targetHabit;
      bool wasCompleted = false;

      for (final h in cachedHabits) {
        if (h.id == habitId) {
          targetHabit = h;
          wasCompleted = h.completedDates.contains(todayStr);
          break;
        }
      }

      if (targetHabit == null) return;

      // If a specific target completion state was requested and is already met,
      // skip to avoid flipping back and forth between background worker and foreground app.
      if (desiredCompleted != null && wasCompleted == desiredCompleted) {
        debugPrint(
            '[HomeWidget] Habit $habitId already in desired state ($desiredCompleted). Skipping toggle.');
        markHandled(habitId);
        return;
      }

      markHandled(habitId);

      final updated = cachedHabits.map((h) {
        if (h.id != habitId) return h;
        final newCompleted = List<String>.from(h.completedDates);
        final newSkipped = List<String>.from(h.skippedDates);
        int newStreak = h.currentStreak;
        int newTotal = h.totalCompleted;
        if (wasCompleted) {
          newCompleted.remove(todayStr);
          if (newStreak > 0) newStreak--;
          if (newTotal > 0) newTotal--;
        } else {
          if (!newCompleted.contains(todayStr)) newCompleted.add(todayStr);
          newSkipped.remove(todayStr);
          newStreak++;
          newTotal++;
        }
        return h.copyWith(
          completedDates: newCompleted,
          skippedDates: newSkipped,
          currentStreak: newStreak,
          totalCompleted: newTotal,
        );
      }).toList();

      await JsonFileCache.write(
        'habits_cache',
        updated.map((h) => h.toJson()).toList(),
      );

      final streak = calculateCurrentStreak(updated);
      await syncHabitsData(habits: updated, overallStreak: streak);

      if (!habitId.startsWith('temp_')) {
        try {
          final client = DioClient();
          if (wasCompleted) {
            await client.dio.delete('/habit-logs/$habitId/$todayStr');
          } else {
            await client.dio.post('/habit-logs', data: {
              'habitId': habitId,
              'date': todayStr,
            });
          }
        } catch (_) {
          await SyncManager.instance.enqueue(
            SyncAction(
              type: SyncActionType.toggleHabit,
              endpoint: wasCompleted
                  ? '/habit-logs/$habitId/$todayStr'
                  : '/habit-logs',
              method: wasCompleted ? 'DELETE' : 'POST',
              payload:
                  wasCompleted ? null : {'habitId': habitId, 'date': todayStr},
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[HomeWidget] Error in background toggle: $e');
    }
  }

  /// Check and process any habit toggles performed on the widget while app was backgrounded/closed
  Future<void> processPendingToggles(WidgetRef ref) async {
    try {
      final pendingStr =
          await HomeWidget.getWidgetData<String>('pending_widget_toggles');
      if (pendingStr == null || pendingStr.isEmpty || pendingStr == '[]') {
        return;
      }

      final list = jsonDecode(pendingStr) as List<dynamic>;
      if (list.isEmpty) return;

      final converted = <Map<String, dynamic>>[];
      for (final item in list) {
        if (item is Map) {
          converted.add(Map<String, dynamic>.from(item));
          final id = item['id'] as String?;
          if (id != null && id.isNotEmpty) {
            markHandled(id);
          }
        }
      }

      // Batch apply all pending toggles at once to eliminate staggered one-by-one delays
      if (converted.isNotEmpty) {
        await ref
            .read(habitsProvider.notifier)
            .batchApplyWidgetToggles(converted);
      }

      // Clear pending queue in widget storage
      await HomeWidget.saveWidgetData<String>(
        'pending_widget_toggles',
        '[]',
      );
    } catch (e) {
      debugPrint('[HomeWidget] Error processing pending widget toggles: $e');
    }
  }

  void dispose() {
    _widgetClickSubscription?.cancel();
  }
}
