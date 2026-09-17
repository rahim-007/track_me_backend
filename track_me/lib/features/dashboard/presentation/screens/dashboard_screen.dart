import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../habits/providers/habits_provider.dart';
import '../../../habits/providers/missed_habits_provider.dart';
import '../../../habits/presentation/widgets/missed_habits_reflection_dialog.dart';
import '../../../habits/presentation/widgets/add_habit_dialog.dart';
import '../../../goals/providers/goals_provider.dart';
import '../../../goals/presentation/widgets/add_goal_dialog.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../cashflow/providers/cashflow_provider.dart';
import '../../../cashflow/data/models/cashflow_models.dart';
import '../../../cashflow/presentation/widgets/cashflow_hero_card.dart';
import '../../../cashflow/presentation/widgets/add_entry_sheet.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../goals/data/models/goal_model.dart';

String _formatGreetingName(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'UrDay User';
  final words = raw.trim().split(' ');
  return words.map((w) {
    if (w.isEmpty) return '';
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

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

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _hasShownReflection = false;
  late DateTime _lastActiveDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger background sync when app comes to foreground
      unawaited(SyncManager.instance.sync());

      final now = DateTime.now();
      final isNewDay = now.year != _lastActiveDate.year ||
          now.month != _lastActiveDate.month ||
          now.day != _lastActiveDate.day;

      _lastActiveDate = now;

      if (isNewDay) {
        // Date changed across midnight while app was in background — refresh reflection
        _hasShownReflection = false;
        ref.invalidate(missedYesterdayHabitsProvider);
        ref.invalidate(habitsProvider);
        ref.invalidate(todayHabitsProvider);
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showAddHabitModal() {
    showDialog<void>(
      context: context,
      builder: (_) => const AddHabitDialog(),
    );
  }

  void _showAddGoalModal() {
    showDialog<void>(
      context: context,
      builder: (_) => const AddGoalDialog(),
    );
  }

  void _showAddExpenseModal() async {
    await AddEntrySheet.show(context, initialKindIndex: 1);
  }

  void _showAddIncomeModal() async {
    await AddEntrySheet.show(context, initialKindIndex: 0);
  }

  void _showReflectionDialog(List<HabitModel> missedHabits) {
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

  @override
  Widget build(BuildContext context) {
    // Watch themeProvider to rebuild instantly when Dark Mode is toggled
    ref.watch(themeProvider);

    // Watch missed yesterday habits
    final missedYesterdayAsync = ref.watch(missedYesterdayHabitsProvider);
    final missedYesterday = missedYesterdayAsync.valueOrNull ?? [];

    // Trigger dialog if missed habits already loaded on initial frame
    if (!_hasShownReflection && missedYesterday.isNotEmpty) {
      _hasShownReflection = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showReflectionDialog(missedYesterday);
      });
    }

    // Listen for missed habits from yesterday to show reflection dialog when loaded asynchronously
    ref.listen<AsyncValue<List<HabitModel>>>(
      missedYesterdayHabitsProvider,
      (prev, next) {
        if (_hasShownReflection) return;
        next.whenData((missedHabits) {
          if (missedHabits.isNotEmpty && mounted) {
            _hasShownReflection = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showReflectionDialog(missedHabits);
            });
          }
        });
      },
    );

    final profile = ref.watch(profileProvider);
    final habitsAsync = ref.watch(todayHabitsProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);
    final cashFlow = ref.watch(cashFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          profile.when(
                            data: (user) => Text(
                              _formatGreetingName(user?.name),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () =>
                                const ShimmerBox(width: 140, height: 26),
                            error: (_, __) => Text(
                              _formatGreetingName(null),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consistency today. Success tomorrow.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification Bell Button
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLine),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          NotificationBell(
                            size: 22,
                            color: AppColors.primary,
                          ),
                          Positioned(
                            top: 11,
                            right: 11,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // User Avatar
                    profile.when(
                      data: (user) => Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: buildAvatarWidget(
                            user?.avatarUrl,
                            name: user?.name ?? 'UrDay User',
                            fontSize: 16,
                            iconColor: AppColors.primary,
                          ),
                        ),
                      ),
                      loading: () => const ShimmerBox(
                        width: 46,
                        height: 46,
                        borderRadius: 23,
                      ),
                      error: (_, __) => Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.person, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Scrollable Content ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── 0. Yesterday's Missed Habits Reflection Banner ────────
                  if (missedYesterday.isNotEmpty) ...[
                    _MissedHabitsBanner(
                      missedHabits: missedYesterday,
                      onTap: () => _showReflectionDialog(missedYesterday),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── 2. Your Progress Hero Card ────────────────────────────
                  _ProgressBannerCard(
                    habits: habitsAsync.value ?? [],
                  ),

                  const SizedBox(height: 20),

                  // ─── 3. Metrics Stats Row ──────────────────────────────────
                  Builder(
                    builder: (context) {
                      final habits = habitsAsync.value ?? [];
                      final profileStats = ref.watch(userProfileStatsProvider);
                      final userStreak = profileStats.currentStreak;

                      return RepaintBoundary(
                        child: _MetricsStatsRow(
                          streakCount: userStreak,
                          habitsCount: habits.where((h) => h.isCompletedToday).length,
                          goalsCount: goalsAsync.value?.length ?? 0,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ─── 4. Today's Habits Section ────────────────────────────
                  RepaintBoundary(
                    child: _TodaysHabitsSection(
                      habits: habitsAsync.value ?? [],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── 5. Cash Flow Hero Card Section ───────────────────────
                  RepaintBoundary(
                    child: _CashFlowSnapshotCard(cashFlowState: cashFlow),
                  ),

                  const SizedBox(height: 24),

                  // ─── 6. Active Goals Section ──────────────────────────────
                  RepaintBoundary(
                    child: _ActiveGoalsSection(
                      goals: goalsAsync.value ?? [],
                      onAddGoal: _showAddGoalModal,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── 7. Quick Action Row ───────────────────────────────────
                  RepaintBoundary(
                    child: _QuickActionsRow(
                      onAddHabit: _showAddHabitModal,
                      onAddGoal: _showAddGoalModal,
                      onAddExpense: _showAddExpenseModal,
                      onAddIncome: _showAddIncomeModal,
                    ),
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

// ─── 0. Missed Habits Reflection Banner Widget ────────────────────────────────

class _MissedHabitsBanner extends StatelessWidget {
  final List<HabitModel> missedHabits;
  final VoidCallback onTap;

  const _MissedHabitsBanner({
    required this.missedHabits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = missedHabits.length;
    final isDark = AppColors.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D10) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF854D0E) : const Color(0xFFFDE68A),
              width: 1.5,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF452C16) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Yesterday's Reflection",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You missed $count ${count == 1 ? 'habit' : 'habits'}. Tap to reflect.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Reflect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. Hero Progress Card Widget ─────────────────────────────────────────────

class _ProgressBannerCard extends StatelessWidget {
  final List<HabitModel> habits;

  const _ProgressBannerCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    final stats = calculateWeeklyHabitStats(habits);
    final displayPercent = stats.percent;
    final progressFactor = (displayPercent / 100.0).clamp(0.0, 1.0);
    final gradientColors = [const Color(0xFF5848D6), const Color(0xFF4930D8)];

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: gradientColors.first,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Exact Mountain Illustration Asset with Flag, Clouds and Winding Road
            Positioned(
              right: -10,
              bottom: -18,
              width: 260,
              height: 195,
              child: Image.asset(
                'assets/images/mountain_illustration.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(painter: _MountainPainter());
                },
              ),
            ),
            // Left Accent Vertical Line (Matching Goal & Habit banners)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: const Color(0xFF8B6EF5),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Weekly Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.92),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'This Week',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$displayPercent%',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // White Progress Line Bar
                      SizedBox(
                        width: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressFactor.clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.25),
                            color: Colors.white,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stats.scheduledCount > 0
                            ? '${stats.completedCount} of ${stats.scheduledCount} completed this week'
                            : (habits.isEmpty ? "Keep going! You're doing great." : 'No habits scheduled yet'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Metrics Stats Row Widget ──────────────────────────────────────────────

class _MetricsStatsRow extends StatelessWidget {
  final int streakCount;
  final int habitsCount;
  final int goalsCount;

  const _MetricsStatsRow({
    required this.streakCount,
    required this.habitsCount,
    required this.goalsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Day Streak Card
        Expanded(
          child: _StatCard(
            iconWidget: const Text('🔥', style: TextStyle(fontSize: 22)),
            value: '$streakCount',
            title: 'Day Streak',
            subtitleWidget: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFFFF6B00)
                        : (AppColors.isDarkMode
                            ? const Color(0xFF323043)
                            : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 2. Habits Completed Card
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.isDarkMode
                    ? const Color(0x2810B981)
                    : const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            value: '$habitsCount',
            title: 'Habits Completed',
            subtitle: 'This Week',
          ),
        ),
        const SizedBox(width: 12),
        // 3. Goals Active Card
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            value: '$goalsCount',
            title: 'Goals Active',
            subtitle: 'On Track',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget iconWidget;
  final String value;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;

  const _StatCard({
    required this.iconWidget,
    required this.value,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLine),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (subtitleWidget != null)
            subtitleWidget!
          else if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 4. Today's Habits Section Widget ─────────────────────────────────────────

class _TodaysHabitsSection extends ConsumerWidget {
  final List<HabitModel> habits;

  const _TodaysHabitsSection({required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledHabits = habitsScheduledOn(habits, DateTime.now());
    final completedCount = scheduledHabits.where((h) => h.isCompletedToday).length;
    final totalCount = scheduledHabits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  "Today's Habits",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (totalCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.habits),
              child: Text(
                'View All >',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (scheduledHabits.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLine),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Habits Scheduled Today',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add a new habit to start building consistency.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduledHabits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = scheduledHabits[index];
              final isDone = habit.isCompletedToday;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : AppColors.borderLine,
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Category Icon Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDone
                              ? (AppColors.isDarkMode
                                  ? const Color(0x2810B981)
                                  : const Color(0xFFECFDF5))
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            (habit.emoji != null && habit.emoji!.trim().isNotEmpty)
                                ? habit.emoji!
                                : _getCategoryEmoji(habit.category),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Habit Name & Category Tag
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    habit.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    habit.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${calculateHabitStreak(habit)} day streak',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interactive Checkbox Toggle Button
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(habitsProvider.notifier)
                              .toggleCompletion(habit, DateTime.now(), debounce: true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isDone
                                ? null
                                : Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                          ),
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
      case 'health':
        return '💪';
      case 'reading':
      case 'education':
        return '📖';
      case 'mindfulness':
        return '🧘';
      case 'finance':
        return '💰';
      default:
        return '🏆';
    }
  }
}

// ─── 5. Active Goals Section Widget ───────────────────────────────────────────

class _ActiveGoalsSection extends StatelessWidget {
  final List<GoalModel> goals;
  final VoidCallback onAddGoal;

  const _ActiveGoalsSection({
    required this.goals,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final activeGoals = goals
        .where((g) =>
            g.status.toLowerCase() != 'completed' &&
            g.status.toLowerCase() != 'archived')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  'Active Goals',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (activeGoals.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeGoals.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.goals),
              child: Text(
                'View All >',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (activeGoals.isEmpty)
          GestureDetector(
            onTap: onAddGoal,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLine),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Your First Goal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track milestones and achieve your dream targets.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: activeGoals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final goal = activeGoals[index];
                final progressPercent = (goal.progress * 100).round();
                final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
                final daysText = daysLeft > 0 ? '$daysLeft days left' : (daysLeft == 0 ? 'Due today' : 'Overdue');

                return GestureDetector(
                  onTap: () => context.go(AppRoutes.goals),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLine),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                goal.category,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: goal.progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.isDarkMode
                                    ? const Color(0xFF282836)
                                    : const Color(0xFFF1EFF8),
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  daysText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── 6. Quick Actions Grid Widget ─────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddHabit;
  final VoidCallback onAddGoal;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  const _QuickActionsRow({
    required this.onAddHabit,
    required this.onAddGoal,
    required this.onAddExpense,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. Add Habit
          _QuickActionButton(
            icon: Icons.add_rounded,
            bgColor: const Color(0xFF5334EA),
            title: 'Add Habit',
            subtitle: 'Build Consistency',
            onTap: onAddHabit,
          ),
          const SizedBox(width: 10),
          // 2. Add Goal
          _QuickActionButton(
            icon: Icons.flag_rounded,
            bgColor: const Color(0xFF5334EA),
            title: 'Add Goal',
            subtitle: 'Stay Focused',
            onTap: onAddGoal,
          ),
          const SizedBox(width: 10),
          // 3. Add Expense
          _QuickActionButton(
            icon: Icons.account_balance_wallet_rounded,
            bgColor: const Color(0xFFEF4444),
            title: 'Add Expense',
            subtitle: 'Track Spending',
            onTap: onAddExpense,
          ),
          const SizedBox(width: 10),
          // 4. Add Income
          _QuickActionButton(
            icon: Icons.arrow_downward_rounded,
            bgColor: const Color(0xFF10B981),
            title: 'Add Income',
            subtitle: 'Track Earnings',
            onTap: onAddIncome,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLine),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 7. Cash Flow Hero Card Widget ────────────────────────────────────────

class _CashFlowSnapshotCard extends StatelessWidget {
  final CashFlowState cashFlowState;

  const _CashFlowSnapshotCard({required this.cashFlowState});

  @override
  Widget build(BuildContext context) {
    final period = cashFlowState.current.asData?.value ??
        CashFlowPeriodModel(
          id: 'current',
          month: DateTime.now().month,
          year: DateTime.now().year,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cash Flow',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.cashflow),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // The Signature Hero Financial Card (Compact Dashboard Mode)
        CashFlowHeroCard(
          period: period,
          isCompact: true,
          onTap: () => context.go(AppRoutes.cashflow),
        ),
      ],
    );
  }
}

// ─── Custom Mountain Graphic Painter ──────────────────────────────────────────

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─── 1. Clouds ──────────────────────────────────────────────────────────
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.fill;

    _drawCloud(canvas, cloudPaint, Offset(w * 0.48, h * 0.20), 16);
    _drawCloud(canvas, cloudPaint, Offset(w * 0.20, h * 0.32), 13);
    _drawCloud(canvas, cloudPaint, Offset(w * 0.88, h * 0.34), 12);

    // ─── 2. Birds ───────────────────────────────────────────────────────────
    final birdPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawBird(canvas, birdPaint, Offset(w * 0.60, h * 0.26), 5);
    _drawBird(canvas, birdPaint, Offset(w * 0.35, h * 0.42), 4);

    // ─── 3. Background Mountain Layers ──────────────────────────────────────
    final paint = Paint()..style = PaintingStyle.fill;

    // Far right back mountain
    final farRightPath = Path()
      ..moveTo(w * 0.75, h)
      ..lineTo(w * 0.92, h * 0.32)
      ..lineTo(w * 1.10, h)
      ..close();
    paint.color = const Color(0x30FFFFFF);
    canvas.drawPath(farRightPath, paint);

    // Back left mountain
    final backLeftPath = Path()
      ..moveTo(w * 0.05, h)
      ..lineTo(w * 0.42, h * 0.45)
      ..lineTo(w * 0.70, h)
      ..close();
    paint.color = const Color(0x25FFFFFF);
    canvas.drawPath(backLeftPath, paint);

    // ─── 4. Main Summit Mountain Peak ────────────────────────────────────────
    final peakX = w * 0.80;
    final peakY = h * 0.16;

    // Left shaded side of main mountain
    final mainLeftPath = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(w * 0.20, h)
      ..lineTo(w * 0.80, h)
      ..close();
    paint.color = const Color(0x3DFFFFFF);
    canvas.drawPath(mainLeftPath, paint);

    // Right highlighted side of main mountain
    final mainRightPath = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(w * 0.80, h)
      ..lineTo(w * 1.15, h)
      ..close();
    paint.color = const Color(0x5EFFFFFF);
    canvas.drawPath(mainRightPath, paint);

    // Foreground left overlapping ridge
    final frontRidgeLeft = Path()
      ..moveTo(w * 0.52, h * 0.42)
      ..lineTo(w * 0.15, h)
      ..lineTo(w * 0.65, h)
      ..close();
    paint.color = const Color(0x4DFFFFFF);
    canvas.drawPath(frontRidgeLeft, paint);

    // Foreground right overlapping ridge
    final frontRidgeRight = Path()
      ..moveTo(w * 0.52, h * 0.42)
      ..lineTo(w * 0.65, h)
      ..lineTo(w * 0.88, h)
      ..close();
    paint.color = const Color(0x70FFFFFF);
    canvas.drawPath(frontRidgeRight, paint);

    // ─── 5. Snow Cap at Summit ──────────────────────────────────────────────
    final snowPath = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(peakX - 16, peakY + 30)
      ..lineTo(peakX - 6, peakY + 26)
      ..lineTo(peakX, peakY + 34)
      ..lineTo(peakX + 8, peakY + 25)
      ..lineTo(peakX + 18, peakY + 32)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(snowPath, paint);

    // ─── 6. Summit Flag & Pole ──────────────────────────────────────────────
    final polePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(peakX, peakY), Offset(peakX, peakY - 22), polePaint);

    final flagPath = Path()
      ..moveTo(peakX, peakY - 22)
      ..cubicTo(
        peakX + 8, peakY - 24,
        peakX + 12, peakY - 18,
        peakX + 20, peakY - 20,
      )
      ..lineTo(peakX + 20, peakY - 10)
      ..cubicTo(
        peakX + 12, peakY - 8,
        peakX + 8, peakY - 14,
        peakX, peakY - 12,
      )
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(flagPath, paint);

    // ─── 7. Winding Pathway ──────────────────────────────────────────────────
    final pathPaint = Paint()
      ..color = const Color(0xEEEDEBFD)
      ..style = PaintingStyle.fill;

    // Pathway ribbon narrowing smoothly towards top
    final roadPath = Path();
    roadPath.moveTo(peakX - 1, peakY + 28);
    roadPath.cubicTo(
      peakX - 8, peakY + 60,
      w * 0.66, h * 0.50,
      w * 0.70, h * 0.62,
    );
    roadPath.cubicTo(
      w * 0.74, h * 0.72,
      w * 0.62, h * 0.78,
      w * 0.66, h * 0.88,
    );
    roadPath.cubicTo(
      w * 0.70, h * 0.95,
      w * 0.75, h,
      w * 0.76, h,
    );

    roadPath.lineTo(w * 0.95, h);
    roadPath.cubicTo(
      w * 0.86, h,
      w * 0.78, h * 0.93,
      w * 0.76, h * 0.86,
    );
    roadPath.cubicTo(
      w * 0.74, h * 0.76,
      w * 0.84, h * 0.70,
      w * 0.78, h * 0.58,
    );
    roadPath.cubicTo(
      w * 0.72, h * 0.48,
      peakX + 4, peakY + 50,
      peakX + 2, peakY + 28,
    );
    roadPath.close();

    canvas.drawPath(roadPath, pathPaint);

    // Dashed Center Line on Pathway
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.90)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerPath = Path();
    centerPath.moveTo(w * 0.85, h);
    centerPath.cubicTo(
      w * 0.78, h * 0.94,
      w * 0.70, h * 0.86,
      w * 0.72, h * 0.76,
    );
    centerPath.cubicTo(
      w * 0.74, h * 0.66,
      w * 0.70, h * 0.56,
      peakX, peakY + 30,
    );

    canvas.drawPath(centerPath, dashPaint);
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double radius) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.2),
      radius * 0.65,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.2),
      radius * 0.7,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          center.dx - radius * 1.3,
          center.dy,
          center.dx + radius * 1.4,
          center.dy + radius * 0.9,
        ),
        Radius.circular(radius * 0.5),
      ),
      paint,
    );
  }

  void _drawBird(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path()
      ..moveTo(center.dx - size, center.dy)
      ..quadraticBezierTo(
        center.dx - size / 2,
        center.dy - size * 0.7,
        center.dx,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + size / 2,
        center.dy - size * 0.7,
        center.dx + size,
        center.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
