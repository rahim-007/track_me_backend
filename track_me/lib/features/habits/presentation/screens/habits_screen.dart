import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import '../widgets/add_habit_dialog.dart';

import '../widgets/flame_explosion_overlay.dart';
import '../widgets/habit_grid_row.dart';
import '../widgets/skip_reason_dialog.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';

/// Toggle for 3D Animations & FX in Habits.
final isHabit3dFxEnabledProvider = StateProvider<bool>((_) => true);

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  DateTime _selectedDate = DateTime.now();

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddHabitDialog(),
    );
  }

  void _showSkipReasonDialog(HabitModel habit, DateTime date) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SkipReasonDialog(habit: habit, date: date),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  int _calculateMaxStreak(List<HabitModel> habits) {
    int maxStreak = 0;
    for (final habit in habits) {
      final currentStreak = calculateHabitStreak(habit);
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
    }
    return maxStreak;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            // Only habits scheduled (Repeat) for the selected day are shown.
            // A habit with no repeat day selected is treated as daily so it
            // never disappears from the list.
            final weekdayIndex = _selectedDate.weekday - 1; // 0 = Monday
            final visibleHabits = habits.where((h) {
              final hasRepeatDay = h.repeatDays.any((d) => d);
              if (!hasRepeatDay) return true;
              return weekdayIndex >= 0 &&
                  weekdayIndex < h.repeatDays.length &&
                  h.repeatDays[weekdayIndex];
            }).toList();

            final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final completedCount =
                visibleHabits.where((h) => h.completedDates.contains(selectedDateStr)).length;
            final totalCount = visibleHabits.length;
            final progress =
                totalCount > 0 ? completedCount / totalCount : 0.0;
            final percentage = (progress * 100).round();
            final streak = _calculateMaxStreak(habits);

            return CustomScrollView(
              slivers: [
                // Top Custom Header: Greeting & Notifications
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Consistency today. Success tomorrow.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final is3d =
                                    ref.watch(isHabit3dFxEnabledProvider);
                                return InkWell(
                                  onTap: () => ref
                                      .read(isHabit3dFxEnabledProvider.notifier)
                                      .state = !is3d,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: is3d
                                          ? AppColors.primary.withOpacity(0.12)
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: is3d
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      is3d ? '✨ 3D ON' : '3D OFF',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: is3d
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            const NotificationBell(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Side-by-Side Dashboard Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Left Card: Progress
                        Expanded(
                          child: Container(
                            height: 124,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.progressCardGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(AppColors.isDarkMode ? 0.10 : 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Today's Progress",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$completedCount/$totalCount Completed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Almost there!",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Circular Progress Ring
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 5.5,
                                        backgroundColor: AppColors.primary.withOpacity(0.12),
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                      Center(
                                        child: Text(
                                          '$percentage%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right Card: Streak
                        Expanded(
                          child: Container(
                            height: 124,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.streakCardGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEA580C).withOpacity(AppColors.isDarkMode ? 0.08 : 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$streak Day Streak',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.streakText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Current Streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.streakText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Keep it up!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal Calendar Date Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _WeekDaySelector(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      onPreviousWeek: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                      },
                      onNextWeek: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                      },
                    ),
                  ),
                ),

                // Habits List Container — only habits that repeat on the
                // selected day are shown here.
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: visibleHabits.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: EmptyStateWidget(
                              icon: habits.isEmpty
                                  ? Icons.track_changes_rounded
                                  : Icons.event_available_rounded,
                              title: habits.isEmpty
                                  ? 'No habits yet'
                                  : 'Nothing scheduled today',
                              subtitle: habits.isEmpty
                                  ? 'Tap the button below to add your first habit'
                                  : 'No habit repeats on this day.\nPick another date or add this day in Repeat.',
                              actionLabel: habits.isEmpty ? 'Add Habit' : null,
                              onAction: habits.isEmpty ? _showAddHabitDialog : null,
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = visibleHabits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: HabitGridRow(
                                  habit: habit,
                                  selectedDate: _selectedDate,
                                  onComplete: (date) {
                                    final dateStr =
                                        DateFormat('yyyy-MM-dd').format(date);
                                    final isCompleting = !habit
                                        .completedDates
                                        .contains(dateStr);
                                    ref
                                        .read(habitsProvider.notifier)
                                        .toggleCompletion(habit, date);

                                    if (isCompleting &&
                                        completedCount + 1 == totalCount) {
                                      final is3d = ref
                                          .read(isHabit3dFxEnabledProvider);
                                      if (is3d) {
                                        FlameExplosionOverlay.show(context);
                                      }
                                    }
                                  },
                                  onSkip: (date) => _showSkipReasonDialog(habit, date),
                                ),
                              );
                            },
                            childCount: visibleHabits.length,
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyStateWidget(
                icon: Icons.cloud_off_rounded,
                title: "Couldn't load habits",
                subtitle: 'Check your connection and try again',
                actionLabel: 'Try Again',
                onAction: () => ref.read(habitsProvider.notifier).loadHabits(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9061FF), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─── Week Day Selector Widget ──────────────────────────────────────────────────

class _WeekDaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const _WeekDaySelector({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final rangeStr = "${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}";

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: AppColors.primary),
              onPressed: onPreviousWeek,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              rangeStr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              onPressed: onNextWeek,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final date = startOfWeek.add(Duration(days: i));
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primary.withOpacity(0.65) : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primaryContainer : Colors.transparent),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? AppColors.primary : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
