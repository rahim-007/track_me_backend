import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../notifications/presentation/widgets/notification_bell.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../habits/providers/habits_provider.dart';
import '../../../habits/providers/missed_habits_provider.dart';
import '../../../habits/presentation/widgets/missed_habits_reflection_dialog.dart';
import '../../../habits/presentation/widgets/skip_reason_dialog.dart';
import '../../../goals/providers/goals_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../cashflow/providers/cashflow_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../goals/data/models/goal_model.dart';

/// Habits that are scheduled on [date]. A habit with no repeat day selected is
/// treated as daily so it never disappears from the dashboard.
@visibleForTesting
List<HabitModel> habitsScheduledOn(List<HabitModel> habits, DateTime date) {
  final weekdayIndex = date.weekday - 1; // 0 = Monday
  return habits.where((h) {
    final hasRepeatDay = h.repeatDays.any((d) => d);
    if (!hasRepeatDay) return true;
    return weekdayIndex >= 0 &&
        weekdayIndex < h.repeatDays.length &&
        h.repeatDays[weekdayIndex];
  }).toList();
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _quoteIndex = 0;
  bool _hasShownReflection = false;

  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(AppConstants.motivationalQuotes.length);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    // Listen for missed habits from yesterday to show reflection dialog
    ref.listen<AsyncValue<List<dynamic>>>(
      missedYesterdayHabitsProvider,
      (prev, next) {
        if (_hasShownReflection) return;
        next.whenData((missedHabits) {
          if (missedHabits.isNotEmpty && mounted) {
            _hasShownReflection = true;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => MissedHabitsReflectionDialog(
                missedHabits: List.from(missedHabits),
                onSubmitted: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            );
          }
        });
      },
    );

    final profile = ref.watch(profileProvider);
    final habitsAsync = ref.watch(todayHabitsProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              toolbarHeight: 90,
              backgroundColor: AppColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        profile.when(
                          data: (user) => Row(
                            children: [
                              Text(
                                user?.name ?? 'Friend',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          loading: () =>
                              const ShimmerBox(width: 120, height: 24),
                          error: (_, __) => Text(
                            'Friend 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell → Notification Center
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.isDarkMode
                              ? Colors.transparent
                              : Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const NotificationBell(size: 22, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  profile.when(
                    data: (user) => Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.isDarkMode
                                ? Colors.transparent
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: buildAvatarWidget(
                          user?.avatarUrl,
                          name: user?.name ?? 'User',
                          fontSize: 14,
                          iconColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    loading: () => const ShimmerBox(
                        width: 42, height: 42, borderRadius: 21),
                    error: (_, __) => Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDD6FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('👨‍💻', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quote Card
                  _CustomQuoteCard(
                    quote: AppConstants.motivationalQuotes[_quoteIndex],
                    onRefresh: () => setState(() {
                      _quoteIndex = Random().nextInt(
                        AppConstants.motivationalQuotes.length,
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Today's Progress Cards
                  habitsAsync.when(
                    data: (habits) => _ProgressSection(
                        habits: habits, profile: profile.value),
                    loading: () => const _ProgressSectionSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Cash Flow Summary Card
                  const _CashFlowDashboardSection(),

                  const SizedBox(height: 24),

                  // Today's Habits
                  _SectionHeader(
                    title: "Today's Habits",
                    onViewAll: () => context.go(AppRoutes.habits),
                  ),
                  const SizedBox(height: 12),
                  habitsAsync.when(
                    data: (habits) {
                      final todaysHabits =
                          habitsScheduledOn(habits, DateTime.now());
                      if (todaysHabits.isEmpty) {
                        return const Center(child: Text("No habits for today"));
                      }
                      final displayed = todaysHabits.take(3).toList();
                      return Column(
                        children: displayed
                            .map((h) => _HabitCompactCard(habit: h))
                            .toList(),
                      );
                    },
                    loading: () => Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: ShimmerBox(height: 70, borderRadius: 16),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Active Goals
                  _SectionHeader(
                    title: 'Active Goals',
                    onViewAll: () => context.go(AppRoutes.goals),
                  ),
                  const SizedBox(height: 12),
                  goalsAsync.when(
                    data: (goals) {
                      if (goals.isEmpty) {
                        return const Center(child: Text("No active goals"));
                      }
                      final displayed = goals.take(2).toList();
                      return Column(
                        children: displayed
                            .map((g) => _GoalCompactCard(goal: g))
                            .toList(),
                      );
                    },
                    loading: () => Column(
                      children: List.generate(
                        2,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: ShimmerBox(height: 80, borderRadius: 16),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Quote Card ────────────────────────────────────────────────────────

class _CustomQuoteCard extends StatelessWidget {
  final String quote;
  final VoidCallback? onRefresh;

  const _CustomQuoteCard({required this.quote, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 136),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            // Mountain Painter
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 180,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: CustomPaint(
                  painter: _MountainPainter(),
                ),
              ),
            ),
            // Quote Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '“',
                    style: TextStyle(
                      fontSize: 40,
                      color: Color(0x73FFFFFF),
                      fontFamily: 'serif',
                      height: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: Text(
                      quote,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      // No maxLines/ellipsis: the card grows via minHeight so the
                      // complete quote is always visible.
                    ),
                  ),
                ],
              ),
            ),
            // Refresh trigger overlay
            if (onRefresh != null)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Section (3 columns) ──────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final List<HabitModel> habits;
  final UserProfile? profile;

  const _ProgressSection({required this.habits, this.profile});

  @override
  Widget build(BuildContext context) {
    // Only count habits that are actually scheduled for today, so a Mon–Fri
    // habit no longer skews the "Habits Done" count on the weekend.
    final todayHabits = habitsScheduledOn(habits, DateTime.now());
    final total = todayHabits.length;
    final completed = todayHabits.where((h) => h.isCompletedToday).length;
    final percent = total > 0 ? completed / total : 0.0;
    final streak = profile?.currentStreak ?? 0;

    // Calculate weekly progress dynamically and retrieve last 7 days completions
    final completedSets = <String, Set<String>>{
      for (final h in habits) h.id: h.completedDates.toSet(),
    };
    final last7DaysCompletions = <double>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final weekdayIndex = (date.weekday - 1) % 7;

      int scheduledCount = 0;
      int completedCount = 0;
      for (final h in habits) {
        if (h.repeatDays[weekdayIndex]) {
          scheduledCount++;
          if (completedSets[h.id]!.contains(dateStr)) {
            completedCount++;
          }
        }
      }
      final rate = scheduledCount > 0 ? completedCount / scheduledCount : 0.0;
      last7DaysCompletions.add(rate);
    }

    double weeklyProgress = 0.0;
    if (last7DaysCompletions.isNotEmpty) {
      weeklyProgress = last7DaysCompletions.reduce((a, b) => a + b) /
          last7DaysCompletions.length;
    }

    return Row(
      children: [
        // Habits Done Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$completed / $total',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Habits Done',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 5,
                          backgroundColor: AppColors.primaryContainer,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(percent * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Day Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? const Color(0xFF452C16)
                            : const Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$streak',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Day Streak',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 15,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _StreakChartPainter(heights: last7DaysCompletions),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Weekly Progress Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? const Color(0xFF113D2D)
                            : const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${(weeklyProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 15,
                  width: double.infinity,
                  child: CustomPaint(
                    painter:
                        _WeeklyProgressPainter(heights: last7DaysCompletions),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressSectionSkeleton extends StatelessWidget {
  const _ProgressSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: ShimmerBox(height: 90, borderRadius: 20)),
        SizedBox(width: 10),
        Expanded(child: ShimmerBox(height: 90, borderRadius: 20)),
        SizedBox(width: 10),
        Expanded(child: ShimmerBox(height: 90, borderRadius: 20)),
      ],
    );
  }
}

// ─── Habit Compact Card ───────────────────────────────────────────────────────

class _HabitCompactCard extends ConsumerWidget {
  final HabitModel habit;
  const _HabitCompactCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = _getCategoryColor(habit.category);
    final isCompleted = habit.isCompletedToday;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isSkipped = habit.skippedDates.contains(todayStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode
                ? Colors.transparent
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color indicator bar
              Container(
                width: 5,
                color: isSkipped ? const Color(0xFFF59E0B) : catColor,
              ),
              const SizedBox(width: 14),
              // Category icon
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSkipped
                      ? const Color(0xFFF59E0B).withOpacity(0.12)
                      : catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    habit.emoji ?? '🎯',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        decoration:
                            isSkipped ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          habit.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                        if (isSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Skipped',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons: Skip + Check
              if (!isCompleted && !isSkipped) ...[
                // Skip Button
                IconButton(
                  tooltip: 'Skip Habit',
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          SkipReasonDialog(habit: habit, date: DateTime.now()),
                    );
                  },
                ),
              ],

              // Checkbox / Status Icon
              GestureDetector(
                onTap: () {
                  if (!isSkipped) {
                    ref
                        .read(habitsProvider.notifier)
                        .toggleCompletion(habit, DateTime.now());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 20),
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : (isSkipped
                              ? const Color(0xFFF59E0B).withOpacity(0.2)
                              : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primary
                            : (isSkipped
                                ? const Color(0xFFF59E0B)
                                : AppColors.border),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : isSkipped
                            ? const Icon(
                                Icons.skip_next_rounded,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              )
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fitness':
      case 'health':
        return const Color(0xFF8B5CF6); // Purple
      case 'learning':
      case 'education':
        return const Color(0xFF3B82F6); // Blue
      case 'mindfulness':
      case 'mental':
        return const Color(0xFF10B981); // Green
      case 'wealth':
        return const Color(0xFF059669); // Emerald
      case 'peace':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF7C3AED); // Default purple
    }
  }
}

// ─── Goal Compact Card ────────────────────────────────────────────────────────

class _GoalCompactCard extends StatelessWidget {
  final GoalModel goal;
  const _GoalCompactCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode
                ? Colors.transparent
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Due ${DateFormat('MMM d, yyyy').format(goal.targetDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.primaryContainer,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Illustration on the right
          SizedBox(
            width: 68,
            height: 68,
            child: CustomPaint(
              painter: _GoalIllustrationPainter(
                category: goal.category,
                name: goal.name,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Back mountain
    final backPath = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = Colors.white.withOpacity(0.08);
    canvas.drawPath(backPath, paint);

    // Front mountain
    final frontPath = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width * 1.1, size.height)
      ..close();
    paint.color = Colors.white.withOpacity(0.12);
    canvas.drawPath(frontPath, paint);

    // Flag pole
    final peakX = size.width * 0.75;
    final peakY = size.height * 0.25;
    final polePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(peakX, peakY), Offset(peakX, peakY - 18), polePaint);

    // Flag
    final flagPath = Path()
      ..moveTo(peakX, peakY - 18)
      ..lineTo(peakX - 12, peakY - 14)
      ..lineTo(peakX, peakY - 10)
      ..close();
    paint.color = Colors.white.withOpacity(0.85);
    canvas.drawPath(flagPath, paint);

    // Birds
    final birdPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    void drawBird(double x, double y, double size) {
      final path = Path()
        ..moveTo(x - size, y)
        ..quadraticBezierTo(x - size / 2, y - size / 2, x, y)
        ..quadraticBezierTo(x + size / 2, y - size / 2, x + size, y);
      canvas.drawPath(path, birdPaint);
    }

    drawBird(size.width * 0.25, size.height * 0.3, 4);
    drawBird(size.width * 0.32, size.height * 0.24, 3);
    drawBird(size.width * 0.52, size.height * 0.35, 4.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StreakChartPainter extends CustomPainter {
  final List<double> heights;
  const _StreakChartPainter({required this.heights});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double barWidth = (size.width - 24) / 7;

    for (int i = 0; i < 7; i++) {
      final x = i * (barWidth + 4);
      final heightFactor = i < heights.length ? heights[i] : 0.05;
      final h = size.height * (heightFactor > 0.05 ? heightFactor : 0.05);
      final y = size.height - h;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(3),
      );

      paint.shader = LinearGradient(
        colors: [
          const Color(0xFFF97316).withOpacity(0.3),
          const Color(0xFFEF4444).withOpacity(0.8),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(x, y, barWidth, h));

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeeklyProgressPainter extends CustomPainter {
  final List<double> heights;
  const _WeeklyProgressPainter({required this.heights});

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final strokePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (heights.length - 1);

    path.moveTo(
        0, size.height * (1.0 - heights[0].clamp(0.0, 1.0) * 0.85 - 0.05));

    for (int i = 1; i < heights.length; i++) {
      final prevX = (i - 1) * stepX;
      final prevY =
          size.height * (1.0 - heights[i - 1].clamp(0.0, 1.0) * 0.85 - 0.05);
      final currX = i * stepX;
      final currY =
          size.height * (1.0 - heights[i].clamp(0.0, 1.0) * 0.85 - 0.05);

      path.cubicTo(
        prevX + stepX * 0.5,
        prevY,
        prevX + stepX * 0.5,
        currY,
        currX,
        currY,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fillPaint.shader = LinearGradient(
      colors: [
        const Color(0xFF10B981).withOpacity(0.2),
        const Color(0xFF10B981).withOpacity(0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);

    final lastX = size.width;
    final lastY =
        size.height * (1.0 - heights.last.clamp(0.0, 1.0) * 0.85 - 0.05);
    final p4 = Offset(lastX, lastY);

    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p4, 4.5, dotPaint);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p4, 1.8, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GoalIllustrationPainter extends CustomPainter {
  final String category;
  final String name;

  _GoalIllustrationPainter({required this.category, required this.name});

  @override
  void paint(Canvas canvas, Size size) {
    final lowerName = name.toLowerCase();
    final lowerCategory = category.toLowerCase();

    if (lowerName.contains('run') ||
        lowerName.contains('marathon') ||
        lowerCategory.contains('fit')) {
      _paintRunner(canvas, size);
    } else if (lowerName.contains('flutter') ||
        lowerCategory.contains('educ') ||
        lowerCategory.contains('learn')) {
      _paintLaptop(canvas, size);
    } else {
      _paintTarget(canvas, size);
    }
  }

  void _paintRunner(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF7C3AED).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
        size.height * 0.45, bgPaint);

    final primaryPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.85)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.45;

    // Head
    canvas.drawCircle(Offset(cx + 6, cy - 14), 3.2, fillPaint);

    // Torso
    canvas.drawLine(
        Offset(cx + 3, cy - 8), Offset(cx - 3, cy + 3), primaryPaint);

    // Front arm
    canvas.drawLine(
        Offset(cx + 2, cy - 7), Offset(cx - 5, cy - 2), primaryPaint);
    canvas.drawLine(
        Offset(cx - 5, cy - 2), Offset(cx - 2, cy + 5), primaryPaint);

    // Back arm
    canvas.drawLine(
        Offset(cx + 2, cy - 7), Offset(cx + 8, cy - 4), primaryPaint);
    canvas.drawLine(
        Offset(cx + 8, cy - 4), Offset(cx + 9, cy + 2), primaryPaint);

    // Front leg
    canvas.drawLine(
        Offset(cx - 3, cy + 3), Offset(cx + 5, cy + 8), primaryPaint);
    canvas.drawLine(
        Offset(cx + 5, cy + 8), Offset(cx + 1, cy + 16), primaryPaint);

    // Back leg
    canvas.drawLine(
        Offset(cx - 3, cy + 3), Offset(cx - 7, cy + 9), primaryPaint);
    canvas.drawLine(
        Offset(cx - 7, cy + 9), Offset(cx - 4, cy + 18), primaryPaint);
  }

  void _paintLaptop(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF3B82F6).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
        size.height * 0.45, bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.7)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 3), width: 34, height: 22),
        const Radius.circular(3),
      ),
      linePaint,
    );

    // Keyboard Base
    final baseField = Path()
      ..moveTo(cx - 22, cy + 8)
      ..lineTo(cx + 22, cy + 8)
      ..lineTo(cx + 18, cy + 11)
      ..lineTo(cx - 18, cy + 11)
      ..close();
    canvas.drawPath(baseField, fillPaint);

    // Flutter chevrons
    final logoPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(cx - 2, cy - 8)
      ..lineTo(cx + 3, cy - 8)
      ..lineTo(cx - 1, cy - 4)
      ..lineTo(cx - 6, cy - 4)
      ..close();
    canvas.drawPath(path1, logoPaint);

    final path2 = Path()
      ..moveTo(cx - 6, cy - 4)
      ..lineTo(cx - 1, cy - 4)
      ..lineTo(cx + 3, cy)
      ..lineTo(cx - 2, cy)
      ..close();
    canvas.drawPath(path2, logoPaint);

    final path3 = Path()
      ..moveTo(cx - 2, cy)
      ..lineTo(cx + 3, cy)
      ..lineTo(cx - 1, cy + 4)
      ..lineTo(cx - 6, cy + 4)
      ..close();
    canvas.drawPath(path3, logoPaint);
  }

  void _paintTarget(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF10B981).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
        size.height * 0.45, bgPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    canvas.drawCircle(Offset(cx, cy), size.height * 0.28, strokePaint);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.16, strokePaint);
    canvas.drawCircle(Offset(cx, cy), size.height * 0.06, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Cash Flow Dashboard Summary Section ─────────────────────────────────────

class _CashFlowDashboardSection extends ConsumerWidget {
  const _CashFlowDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowState = ref.watch(cashFlowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Cash Flow',
          onViewAll: () => context.go(AppRoutes.cashflow),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.go(AppRoutes.cashflow),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cashFlowState.current.when(
              data: (period) {
                final net = period.netCashFlow;
                final isNetPositive = net >= 0;
                final netFormatted =
                    '${isNetPositive ? '+' : ''}₹${NumberFormat('#,##0').format(net)}';

                return Column(
                  children: [
                    Row(
                      children: [
                        // Net cashflow summary tile
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NET CASH FLOW (${period.label.toUpperCase()})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                netFormatted,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isNetPositive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isNetPositive
                                    ? AppColors.success
                                    : AppColors.error)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isNetPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 16,
                                color: isNetPositive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isNetPositive ? 'Positive' : 'Deficit',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isNetPositive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        // Bank closing balance
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat.compact().format(period.closingBank)}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Cash closing balance
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cash',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat.compact().format(period.closingCash)}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (cashFlowState.yetToReceive > 0 ||
                        cashFlowState.yetToGive > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Debt Ledger:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                if (cashFlowState.yetToReceive > 0)
                                  Text(
                                    'To Receive: ₹${NumberFormat.compact().format(cashFlowState.yetToReceive)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                if (cashFlowState.yetToReceive > 0 &&
                                    cashFlowState.yetToGive > 0)
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if (cashFlowState.yetToGive > 0)
                                  Text(
                                    'To Give: ₹${NumberFormat.compact().format(cashFlowState.yetToGive)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const ShimmerBox(height: 120, borderRadius: 16),
              error: (_, __) => Text(
                'Tap to view Cash Flow',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
