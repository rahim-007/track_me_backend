import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import '../widgets/add_habit_dialog.dart';

import '../widgets/habit_grid_row.dart';
import '../widgets/skip_reason_dialog.dart';

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
    if (habits.isEmpty) return 0;
    int maxStreak = 0;
    for (final habit in habits) {
      final completed = habit.completedDates.toSet();
      int currentStreak = 0;
      DateTime day = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        if (completed.contains(dateStr)) {
          currentStreak++;
          day = day.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
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
            final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final completedCount =
                habits.where((h) => h.completedDates.contains(selectedDateStr)).length;
            final totalCount = habits.length;
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
                        // Notification Icon with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications screen coming soon!')),
                                );
                              },
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                size: 28,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
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
                                colors: AppColors.isDarkMode 
                                    ? [const Color(0xFF2D1E54), const Color(0xFF1E143A)] 
                                    : [const Color(0xFFF3F0FF), const Color(0xFFEBE5FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.06),
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
                                colors: AppColors.isDarkMode 
                                    ? [const Color(0xFF452C16), const Color(0xFF352110)] 
                                    : [const Color(0xFFFFF7ED), const Color(0xFFFFEFE0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEA580C).withOpacity(0.04),
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
                                        color: AppColors.isDarkMode ? const Color(0xFFF97316) : const Color(0xFFC2410C),
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
                                    color: AppColors.isDarkMode ? const Color(0xFFF97316) : const Color(0xFFC2410C),
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

                // Habits List Container
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: habits.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: EmptyStateWidget(
                              icon: Icons.track_changes_rounded,
                              title: 'No habits yet',
                              subtitle: 'Tap the button below to add your first habit',
                              actionLabel: 'Add Habit',
                              onAction: _showAddHabitDialog,
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = habits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: HabitGridRow(
                                  habit: habit,
                                  selectedDate: _selectedDate,
                                  onComplete: (date) {
                                    ref.read(habitsProvider.notifier).toggleCompletion(habit, date);
                                  },
                                  onSkip: (date) => _showSkipReasonDialog(habit, date),
                                ),
                              );
                            },
                            childCount: habits.length,
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
