import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../habits/providers/habits_provider.dart';
import '../../../goals/providers/goals_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/constants/app_constants.dart';
import 'dart:math';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _quoteIndex = 0;

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
    final profile = ref.watch(profileProvider);
    final habitsAsync = ref.watch(todayHabitsProvider);
    final goalsAsync = ref.watch(activeGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        profile.when(
                          data: (user) => Text(
                            user?.name ?? 'Friend',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          loading: () => const ShimmerBox(width: 120, height: 20),
                          error: (_, __) => const Text('Friend'),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              actions: const [SizedBox(width: 20)],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quote Card
                  QuoteCard(
                    quote: AppConstants.motivationalQuotes[_quoteIndex],
                    onRefresh: () => setState(() {
                      _quoteIndex = Random().nextInt(
                        AppConstants.motivationalQuotes.length,
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Today's Progress
                  habitsAsync.when(
                    data: (habits) => _TodayProgressSection(habits: habits),
                    loading: () => const _ProgressSectionSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Today's Habits
                  _SectionHeader(
                    title: "Today's Habits",
                    onViewAll: () => context.go(AppRoutes.habits),
                  ),
                  const SizedBox(height: 12),
                  habitsAsync.when(
                    data: (habits) {
                      if (habits.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.track_changes_rounded,
                          title: 'No habits yet',
                          subtitle: 'Add your first habit to get started',
                        );
                      }
                      final displayed = habits.take(3).toList();
                      return Column(
                        children: displayed
                            .map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _HabitCompactCard(habit: h),
                                ))
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
                        return EmptyStateWidget(
                          icon: Icons.flag_rounded,
                          title: 'No goals yet',
                          subtitle: 'Set your first goal to start tracking',
                        );
                      }
                      final displayed = goals.take(2).toList();
                      return Column(
                        children: displayed
                            .map((g) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _GoalCompactCard(goal: g),
                                ))
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

                  const SizedBox(height: 24),

                  // AI Insight Card
                  _AiInsightCard(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _QuickActionsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Progress Section ─────────────────────────────────────────────────

class _TodayProgressSection extends StatelessWidget {
  final List habits;

  const _TodayProgressSection({required this.habits});

  @override
  Widget build(BuildContext context) {
    final total = habits.length;
    final completed = habits.where((h) => h.isCompletedToday).length;
    final percent = total > 0 ? completed / total : 0.0;
    final streak = 7; // Placeholder

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppCard(
            child: Row(
              children: [
                ProgressRing(
                  progress: percent,
                  size: 72,
                  strokeWidth: 7,
                  centerWidget: Text(
                    '${(percent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed/$total',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Habits done',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 10),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  'Day streak',
                  style: Theme.of(context).textTheme.bodySmall,
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
        Expanded(flex: 2, child: ShimmerBox(height: 100, borderRadius: 16)),
        SizedBox(width: 12),
        Expanded(child: ShimmerBox(height: 100, borderRadius: 16)),
      ],
    );
  }
}

// ─── Habit Compact Card ───────────────────────────────────────────────────────

class _HabitCompactCard extends StatelessWidget {
  final dynamic habit;
  const _HabitCompactCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(habit.emoji ?? '✅', style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name ?? 'Habit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  habit.category ?? 'General',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            habit.isCompletedToday
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: habit.isCompletedToday
                ? AppColors.success
                : AppColors.textHint,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// ─── Goal Compact Card ────────────────────────────────────────────────────────

class _GoalCompactCard extends StatelessWidget {
  final dynamic goal;
  const _GoalCompactCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progress ?? 0.0).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name ?? 'Goal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Due ${DateFormat('MMM d, y').format(goal.targetDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── AI Insight Card ──────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You\'ve maintained a great streak this week! Keep going 💪',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'Add Habit',
                color: AppColors.primary,
                onTap: () => context.go(AppRoutes.habits),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.flag_rounded,
                label: 'Add Goal',
                color: AppColors.secondary,
                onTap: () => context.go(AppRoutes.goals),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Tips',
                color: AppColors.accent,
                onTap: () => context.go(AppRoutes.aiInsights),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text(
              'View All →',
              style: TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}
