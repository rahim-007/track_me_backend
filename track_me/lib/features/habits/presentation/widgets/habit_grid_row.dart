import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import 'add_habit_dialog.dart';
import 'habit_3d_checkbox.dart';

class HabitGridRow extends ConsumerWidget {
  final HabitModel habit;
  final DateTime selectedDate;
  final void Function(DateTime date) onComplete;
  final void Function(DateTime date) onSkip;

  const HabitGridRow({
    super.key,
    required this.habit,
    required this.selectedDate,
    required this.onComplete,
    required this.onSkip,
  });

  /// Per-habit streak: consecutive *scheduled* days completed (unscheduled
  /// days are ignored, so a Mon/Wed/Fri habit is never broken by Tue/Thu).
  /// A scheduled day that is skipped or missing breaks the streak.
  int get _streak => calculateHabitStreak(habit);

  Color _getCategoryColor() {
    final cat = habit.category.toLowerCase();
    if (cat.contains('fit')) return const Color(0xFF10B981); // Fitness
    if (cat.contains('learn')) return const Color(0xFF3B82F6); // Learning
    if (cat.contains('mind')) return const Color(0xFF8B5CF6); // Mindfulness
    if (cat.contains('health')) return const Color(0xFFF59E0B); // Health
    if (cat.contains('wealth')) return const Color(0xFF059669); // Wealth
    if (cat.contains('peace')) return const Color(0xFF06B6D4); // Peace
    if (cat.contains('person')) return const Color(0xFFEC4899); // Personal
    if (cat.contains('fin')) return const Color(0xFF059669); // Finance
    return AppColors.primary;
  }

  double get _weeklyCompletionRate {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final completed = habit.completedDates.toSet();
    int completedDaysThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      if (completed.contains(dateStr)) {
        completedDaysThisWeek++;
      }
    }
    int scheduledDays = habit.repeatDays.where((d) => d).length;
    if (scheduledDays == 0) scheduledDays = 7;
    return (completedDaysThisWeek / scheduledDays).clamp(0.0, 1.0);
  }

  bool get _isCompletedToday {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return habit.completedDates.contains(dateStr);
  }

  bool get _isSkippedToday {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return habit.skippedDates.contains(dateStr);
  }

  bool get _isFutureDate {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selectedOnly.isAfter(todayOnly);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor();
    final isDone = _isCompletedToday;
    final isSkipped = _isSkippedToday;
    final isFuture = _isFutureDate;
    final weeklyProgress = _weeklyCompletionRate;
    final streak = _streak;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _showDetailsSheet(context, ref),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.raised,
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 1. Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(AppColors.isDarkMode ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          habit.emoji ?? '🏆',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 2. Middle Content (Name, Category, Streak, Progress Bar)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (streak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.isDarkMode ? const Color(0xFF452C16) : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '🔥 $streak Day',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.isDarkMode ? const Color(0xFFF97316) : const Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(AppColors.isDarkMode ? 0.16 : 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.30),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              habit.category,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Weekly progress bar row
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(begin: 0, end: weeklyProgress),
                                    builder: (context, animVal, _) {
                                      return LinearProgressIndicator(
                                        value: animVal,
                                        minHeight: 6,
                                        backgroundColor: AppColors.primaryContainer,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(weeklyProgress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 3. Tactile 3D Action Circle
                    Consumer(
                      builder: (context, ref, child) {
                        final is3d = ref.watch(isHabit3dFxEnabledProvider);
                        return Habit3dCheckbox(
                          enabled: is3d && !isFuture && !isSkipped,
                          accentColor: categoryColor,
                          onTap: isFuture || isSkipped
                              ? () {}
                              : () => onComplete(selectedDate),
                          child: GestureDetector(
                            onTap: isFuture || isSkipped
                                ? null
                                : () => onComplete(selectedDate),
                            child: child!,
                          ),
                        );
                      },
                      child: AnimatedScale(
                        scale: isDone && !isFuture ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isDone && !isFuture
                                ? AppColors.primaryGradient
                                : null,
                            color: isDone && !isFuture
                                ? null
                                : (isSkipped
                                    ? const Color(0xFFF59E0B).withOpacity(0.16)
                                    : (isFuture
                                        ? AppColors.surfaceVariant
                                        : AppColors.surface)),
                            border: Border.all(
                              color: isDone && !isFuture
                                  ? Colors.transparent
                                  : (isSkipped
                                      ? const Color(0xFFF59E0B)
                                      : (isFuture
                                          ? AppColors.border
                                          : categoryColor.withOpacity(0.60))),
                              width: isDone ? 0 : 2,
                            ),
                            boxShadow: isDone && !isFuture
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : AppShadows.soft,
                          ),
                          child: Center(
                            child: isFuture
                                ? Icon(
                                    Icons.lock_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  )
                                : (isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : (isSkipped
                                        ? const Icon(
                                            Icons.skip_next_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 20,
                                          )
                                        : Icon(
                                            Icons.circle_outlined,
                                            color: categoryColor.withOpacity(0.40),
                                            size: 20,
                                          ))),
                          ),
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
    ),
  );
}

  void _showDetailsSheet(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor();
    final isDone = _isCompletedToday;
    final isSkipped = _isSkippedToday;
    final isFuture = _isFutureDate;
    final weeklyProgress = _weeklyCompletionRate;
    final percentage = (weeklyProgress * 100).round();
    final streak = _streak;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = AppColors.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slide Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header: Emoji & Name & Category
              Row(
                children: [
                  Hero(
                    tag: 'habit_emoji_${habit.id}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          habit.emoji ?? '🏆',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habit.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: categoryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Stats section (Streak, Status, Completion)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Current Streak',
                      value: '$streak Days',
                      icon: '🔥',
                      color: isDark ? AppColors.surfaceVariant : const Color(0xFFFFF3E0),
                      textColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: "Today's Status",
                      value: isSkipped ? 'Skipped' : (isDone ? 'Completed' : 'Pending'),
                      icon: isSkipped ? '⚪' : (isDone ? '✅' : '⏳'),
                      color: isDark
                          ? AppColors.surfaceVariant
                          : (isSkipped
                              ? const Color(0xFFF3F4F6)
                              : (isDone ? const Color(0xFFE8F5E9) : const Color(0xFFEDE7F6))),
                      textColor: isSkipped
                          ? AppColors.textSecondary
                          : (isDone ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF10B981)) : AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Weekly Progress
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Completion Rate',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: weeklyProgress,
                        minHeight: 8,
                        backgroundColor: AppColors.primaryContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Notes section
              if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariant : const Color(0xFFFFF9C4).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.border : const Color(0xFFFFF59D).withOpacity(0.5)),
                  ),
                  child: Text(
                    habit.notes!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            // Edit
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AddHabitDialog(initialHabit: habit),
                  );
                },
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                label: const Text(
                  'Edit Habit',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                if (!isDone && !isSkipped && !isFuture) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onSkip(selectedDate);
                      },
                      icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFF59E0B)),
                      label: const Text(
                        'Skip Today',
                        style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(context, ref);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    label: const Text(
                      'Delete Habit',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            if (isFuture) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '🔒 Habits for future days are locked.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

  Widget _buildStatCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
