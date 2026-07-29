import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';

class HabitGridRow extends ConsumerWidget {
  final HabitModel habit;
  final void Function(DateTime date) onComplete;
  final void Function(DateTime date) onSkip;

  const HabitGridRow({
    super.key,
    required this.habit,
    required this.onComplete,
    required this.onSkip,
  });

  List<DateTime> get _weekDates {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = _weekDates;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          // Habit Info
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      habit.emoji ?? '✅',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        habit.category,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 7-Day Grid
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dates.map((date) {
                final status = _getDayStatus(date);
                final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                final isFuture = date.isAfter(DateTime.now());

                return GestureDetector(
                  onTap: isFuture
                      ? null
                      : status == DayStatus.completed
                          ? null
                          : () => _showActionSheet(context, date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getCircleColor(status, isToday, isFuture),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: _getIcon(status, isFuture),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DayStatus _getDayStatus(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (habit.completedDates.contains(dateStr)) return DayStatus.completed;
    if (habit.skippedDates.contains(dateStr)) return DayStatus.skipped;
    return DayStatus.pending;
  }

  Color _getCircleColor(DayStatus status, bool isToday, bool isFuture) {
    if (isFuture) return AppColors.surfaceVariant;
    switch (status) {
      case DayStatus.completed:
        return AppColors.primary;
      case DayStatus.skipped:
        return AppColors.warningLight;
      case DayStatus.pending:
        return isToday ? AppColors.primaryContainer : AppColors.surfaceVariant;
    }
  }

  Widget _getIcon(DayStatus status, bool isFuture) {
    if (isFuture) return const SizedBox.shrink();
    switch (status) {
      case DayStatus.completed:
        return const Icon(Icons.check_rounded, size: 16, color: Colors.white);
      case DayStatus.skipped:
        return const Icon(Icons.skip_next_rounded, size: 16, color: AppColors.warning);
      case DayStatus.pending:
        return const SizedBox.shrink();
    }
  }

  void _showActionSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success),
              ),
              title: const Text('Mark as Complete'),
              onTap: () {
                Navigator.pop(context);
                onComplete(date);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.skip_next_rounded, color: AppColors.warning),
              ),
              title: const Text('Skip Today'),
              onTap: () {
                Navigator.pop(context);
                onSkip(date);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

enum DayStatus { completed, skipped, pending }
