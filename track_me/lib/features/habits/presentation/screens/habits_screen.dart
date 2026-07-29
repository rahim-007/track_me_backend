import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/habit_grid_row.dart';
import '../widgets/skip_reason_dialog.dart';
import 'dart:math';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(AppConstants.motivationalQuotes.length);
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddHabitDialog(),
    );
  }

  void _showSkipReasonDialog(HabitModel habit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SkipReasonDialog(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Legend'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(color: AppColors.primary, icon: Icons.check_rounded, label: 'Completed'),
                      const SizedBox(height: 8),
                      _LegendRow(color: AppColors.textHint, icon: Icons.radio_button_unchecked_rounded, label: 'Pending'),
                      const SizedBox(height: 8),
                      _LegendRow(color: AppColors.warning, icon: Icons.skip_next_rounded, label: 'Skipped'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
      ),
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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

                      // Week Header
                      _WeekHeader(),

                      const SizedBox(height: 12),

                      if (habits.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyStateWidget(
                            icon: Icons.track_changes_rounded,
                            title: 'No habits yet',
                            subtitle: 'Tap the button below to add your first habit',
                            actionLabel: 'Add Habit',
                            onAction: _showAddHabitDialog,
                          ),
                        )
                      else
                        ...habits.map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: HabitGridRow(
                                habit: habit,
                                onComplete: (date) {
                                  ref
                                      .read(habitsProvider.notifier)
                                      .toggleCompletion(habit, date);
                                },
                                onSkip: (date) =>
                                    _showSkipReasonDialog(habit),
                              ),
                            )),
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendRow({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

// ─── Week Header ──────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  final List<String> _days = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mon...7=Sun

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Label column width
          const SizedBox(width: 120),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final isToday = (i + 1) == today;
                return Column(
                  children: [
                    Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
