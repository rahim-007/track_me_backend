import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/habit_model.dart';
import '../../data/quotes_data.dart';
import '../../providers/habits_provider.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/skip_reason_dialog.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  DateTime _selectedDate = DateTime.now();
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentQuoteIndex = Random().nextInt(kHabitQuotes.length);
  }

  void _nextQuote() {
    setState(() {
      int next;
      do {
        next = Random().nextInt(kHabitQuotes.length);
      } while (next == _currentQuoteIndex && kHabitQuotes.length > 1);
      _currentQuoteIndex = next;
    });
  }

  // Selected week anchor (starts on Sunday or Monday of the selected date)
  DateTime get _weekStartDate {
    final diff = _selectedDate.weekday % 7;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).subtract(Duration(days: diff));
  }

  void _previousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
    });
  }

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

  void _showHabitOptionsMenu(HabitModel habit) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMutedColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      habit.emoji ?? '🏆',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF5334EA)),
                  title: const Text('Edit Habit'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => AddHabitDialog(initialHabit: habit),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Color(0xFFEAB308)),
                  title: const Text('Log Skip / Missed Reason'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSkipReasonDialog(habit, _selectedDate);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  title: const Text('Delete Habit', style: TextStyle(color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(habitsProvider.notifier).deleteHabit(habit.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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

  int _calculateWeeklyCompletions(List<HabitModel> habits) {
    int count = 0;
    final weekDates = List.generate(
      7,
      (i) => DateFormat('yyyy-MM-dd').format(_weekStartDate.add(Duration(days: i))),
    );
    for (final habit in habits) {
      for (final dateStr in weekDates) {
        if (habit.completedDates.contains(dateStr)) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final isDark = AppColors.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            // Filter habits scheduled for the selected date
            final weekdayIndex = _selectedDate.weekday - 1; // 0 = Monday
            final visibleHabits = habits.where((h) {
              final hasRepeatDay = h.repeatDays.any((d) => d);
              if (!hasRepeatDay) return true;
              return weekdayIndex >= 0 &&
                  weekdayIndex < h.repeatDays.length &&
                  h.repeatDays[weekdayIndex];
            }).toList();

            final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final completedCount = visibleHabits
                .where((h) => h.completedDates.contains(selectedDateStr))
                .length;
            final totalCount = visibleHabits.length;
            final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
            final percentage = (progress * 100).round();
            final streak = _calculateMaxStreak(habits);
            final weeklyCompletions = _calculateWeeklyCompletions(habits);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── 1. Header Row ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habits',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Build today. Become tomorrow.',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Filter Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderLine),
                                boxShadow: AppShadows.soft,
                              ),
                              child: Icon(
                                Icons.filter_list_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Add Habit Button
                            GestureDetector(
                              onTap: _showAddHabitDialog,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5334EA),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5334EA).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 2. Quote Hero Banner Card (100 Quotes System) ───────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: GestureDetector(
                      onTap: _nextQuote,
                      child: Container(
                        height: 168,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F4DE1),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5F4DE1), Color(0xFF5143CA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5F4DE1).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final currentQuote = kHabitQuotes[_currentQuoteIndex];
                              final cleanAuthor = currentQuote.author
                                  .replaceAll('Inspired by ', '')
                                  .trim();

                              return Stack(
                                children: [
                                  // Background Hero Banner Graphic (Clipboard Illustration on Right)
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/habit_hero_banner.png',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.centerRight,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  // Left Accent Vertical Line
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 4,
                                      color: const Color(0xFF8B6EF5),
                                    ),
                                  ),
                                  // Left Quote Text Content (strictly left side)
                                  Positioned(
                                    left: 18,
                                    top: 14,
                                    bottom: 14,
                                    right: constraints.maxWidth * 0.44,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '“',
                                              style: TextStyle(
                                                fontSize: 32,
                                                height: 0.85,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFC4B5FD),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildHighlightedQuote(
                                                currentQuote.quote,
                                                isDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 20),
                                          child: Text(
                                            '– $cleanAuthor',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFC4B5FD),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // ─── 3. Metrics Overview Row (4 Stat Cards) ──────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // 1. Completed This Week
                        Expanded(
                          child: _OverviewStatCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x2810B981)
                                    : const Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            value: '$weeklyCompletions',
                            valueColor: const Color(0xFF10B981),
                            title: 'Completed',
                            subtitle: 'This Week',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 2. Total Habits
                        Expanded(
                          child: _OverviewStatCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            value: '${habits.length}',
                            valueColor: AppColors.primary,
                            title: 'Total Habits',
                            subtitle: 'All Time',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 3. Current Streak
                        Expanded(
                          child: _OverviewStatCard(
                            iconWidget: const Text('🔥', style: TextStyle(fontSize: 16)),
                            value: '$streak',
                            valueColor: const Color(0xFFFF6B00),
                            title: 'Current Streak',
                            subtitle: 'Days',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 4. Success Rate
                        Expanded(
                          child: _OverviewStatCard(
                            iconWidget: Icon(
                              Icons.north_east_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            value: '$percentage%',
                            valueColor: AppColors.primary,
                            title: 'Success Rate',
                            subtitle: 'This Week',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ─── 4. This Week Date Strip ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Week Navigation Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'This Week',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _previousWeek,
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatWeekRange(_weekStartDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _nextWeek,
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 7 Days Columns
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final date = _weekStartDate.add(Duration(days: index));
                            final isSelected = DateUtils.isSameDay(date, _selectedDate);
                            final isToday = DateUtils.isSameDay(date, DateTime.now());
                            final dateStr = DateFormat('yyyy-MM-dd').format(date);

                            // Check if all scheduled habits were completed on this date
                            final dayCompleted = habits.isNotEmpty &&
                                habits.any((h) => h.completedDates.contains(dateStr));

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEE').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Status Indicator Dot / Check
                                  if (isSelected)
                                    Column(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF5334EA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF5334EA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (dayCompleted)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderLine,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ─── 5. Today's Habits Section Header ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(
                      builder: (context) {
                        final nowDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                        final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                        final isFutureDate = selectedDay.isAfter(nowDay);

                        String sectionTitle = "Today's Habits";
                        if (DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))) {
                          sectionTitle = "Tomorrow's Habits 🔒";
                        } else if (isFutureDate) {
                          sectionTitle = "${DateFormat('EEEE').format(_selectedDate)}'s Habits 🔒";
                        } else if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
                          sectionTitle = "${DateFormat('MMM d').format(_selectedDate)} Habits";
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sectionTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isFutureDate)
                              Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlocks ${DateFormat('MMM d').format(_selectedDate)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Text(
                                    '$completedCount of $totalCount completed',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? const Color(0xFF282836)
                                            : const Color(0xFFF1EFF8),
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ─── 6. Habits List Cards ─────────────────────────────────────
                visibleHabits.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderLine),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              children: [
                                const Text('🌱', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 12),
                                Text(
                                  'No Habits Scheduled for This Day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap the + button to add a new habit or select another day.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = visibleHabits[index];
                              final isDone = habit.completedDates.contains(selectedDateStr);
                              final accentColor = _getCategoryAccentColor(habit.category);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDone
                                          ? const Color(0xFF10B981).withOpacity(0.3)
                                          : AppColors.borderLine,
                                    ),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          // Left Vertical Color Accent Line
                                          Container(
                                            width: 4.5,
                                            color: accentColor,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14,
                                              ),
                                              child: Row(
                                                children: [
                                                  // Icon Container
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: accentColor.withOpacity(
                                                        isDark ? 0.16 : 0.10,
                                                      ),
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        (habit.emoji != null &&
                                                                habit.emoji!.trim().isNotEmpty)
                                                            ? habit.emoji!
                                                            : _getCategoryEmoji(habit.category),
                                                        style: const TextStyle(fontSize: 24),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  // Middle Info Column
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          habit.name,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppColors.textPrimary,
                                                            decoration: isDone
                                                                ? TextDecoration.lineThrough
                                                                : null,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 3),
                                                        Text(
                                                          _getHabitSubtitle(habit),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
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
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Right Action Button (Completed, Mark Done, or Locked for Future)
                                                  Builder(
                                                    builder: (context) {
                                                      final nowDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                                                      final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                                      final isFutureDate = selectedDay.isAfter(nowDay);

                                                      if (isFutureDate) {
                                                        return GestureDetector(
                                                          onTap: () {
                                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Row(
                                                                  children: [
                                                                    const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                                                                    const SizedBox(width: 8),
                                                                    Expanded(
                                                                      child: Text(
                                                                        'Habits for future dates are locked. Complete them on ${DateFormat('EEEE, MMM d').format(_selectedDate)}!',
                                                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                backgroundColor: const Color(0xFF5334EA),
                                                                behavior: SnackBarBehavior.floating,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                duration: const Duration(seconds: 2),
                                                              ),
                                                            );
                                                          },
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                width: 36,
                                                                height: 36,
                                                                decoration: BoxDecoration(
                                                                  color: isDark ? const Color(0xFF282836) : const Color(0xFFF1EFF8),
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(
                                                                    color: AppColors.borderLine,
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                                child: Icon(
                                                                  Icons.lock_rounded,
                                                                  color: AppColors.textSecondary,
                                                                  size: 18,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Text(
                                                                'Locked',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: AppColors.textSecondary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }

                                                      return GestureDetector(
                                                        onTap: () {
                                                          ref
                                                              .read(habitsProvider.notifier)
                                                              .toggleCompletion(habit, _selectedDate);
                                                        },
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Container(
                                                              width: 36,
                                                              height: 36,
                                                              decoration: BoxDecoration(
                                                                color: isDone
                                                                    ? const Color(0xFF10B981)
                                                                    : Colors.transparent,
                                                                shape: BoxShape.circle,
                                                                border: isDone
                                                                    ? null
                                                                    : Border.all(
                                                                        color: const Color(0xFF5334EA),
                                                                        width: 2,
                                                                      ),
                                                              ),
                                                              child: isDone
                                                                  ? const Icon(
                                                                      Icons.check_rounded,
                                                                      color: Colors.white,
                                                                      size: 20,
                                                                    )
                                                                  : null,
                                                            ),
                                                            const SizedBox(height: 3),
                                                            Text(
                                                              isDone ? 'Completed' : 'Mark Done',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w700,
                                                                color: isDone
                                                                    ? const Color(0xFF10B981)
                                                                    : const Color(0xFF5334EA),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // More Options Button
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.more_vert_rounded,
                                                      color: AppColors.textSecondary,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => _showHabitOptionsMenu(habit),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: visibleHabits.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ─── 7. Weekly Goal Footer Card ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF221C3B)
                            : const Color(0xFFEEECFE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x287551FF)
                              : const Color(0xFFDCD6FF),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Trophy Badge Icon
                          const Text('🏆', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Small habits, big changes.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Stay consistent and the results will follow.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Right Goal Progress Readout
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$weeklyCompletions / 15',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Weekly Goal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (weeklyCompletions / 15).clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: isDark
                                        ? const Color(0xFF322857)
                                        : const Color(0xFFD8D2FF),
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text(
              'Error loading habits: $err',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  String _formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final startFmt = DateFormat('MMM d').format(start);
    final endFmt = DateFormat('MMM d').format(end);
    return '$startFmt – $endFmt';
  }

  Color _getCategoryAccentColor(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
      case 'health':
        return const Color(0xFF10B981);
      case 'reading':
      case 'education':
        return const Color(0xFF3B82F6);
      case 'mindfulness':
        return const Color(0xFFF97316);
      case 'finance':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF5334EA);
    }
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

  String _getHabitSubtitle(HabitModel habit) {
    if (habit.notes != null && habit.notes!.trim().isNotEmpty) {
      return habit.notes!;
    }
    return '${habit.category} • Target 1x/day';
  }

  Widget _buildHighlightedQuote(String text, bool isDark) {
    final highlightWords = [
      'habit', 'habits', 'routine', 'routines', 'consistency', 'discipline',
      'well-being', 'choices', 'investment', 'health', 'care', 'natural', 'body', 'rest',
      'goal', 'goals', 'progress', 'strong', 'future', 'practice', 'small', 'healthy',
      'protect', 'responds', 'move', 'ordinary', 'easier', 'living'
    ];

    final words = text.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final rawWord = words[i];
      final cleanWord = rawWord.replaceAll(RegExp(r'[^\w\-]'), '').toLowerCase();
      final isHighlight = highlightWords.contains(cleanWord);

      spans.add(
        TextSpan(
          text: rawWord + (i < words.length - 1 ? ' ' : ''),
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            color: isHighlight
                ? Colors.white
                : Colors.white.withOpacity(0.92),
          ),
        ),
      );
    }

    return RichText(
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: Colors.white,
        ),
        children: spans,
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final Widget iconWidget;
  final String value;
  final Color valueColor;
  final String title;
  final String subtitle;

  const _OverviewStatCard({
    required this.iconWidget,
    required this.value,
    required this.valueColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLine),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
