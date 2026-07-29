import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/goal_model.dart';
import '../../providers/goals_provider.dart';
import '../widgets/add_goal_dialog.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _quoteIndex = 0;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(AppConstants.goalQuotes.length);
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddGoalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Goal Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Goal'),
      ),
      body: SafeArea(
        child: goalsAsync.when(
          data: (goals) {
            // Group by category
            final categories = goals
                .map((g) => g.category)
                .toSet()
                .toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quote Card
                      QuoteCard(
                        quote: AppConstants.goalQuotes[_quoteIndex],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onRefresh: () => setState(() {
                          _quoteIndex = Random().nextInt(
                            AppConstants.goalQuotes.length,
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Category Filter Chips
                      if (categories.isNotEmpty) ...[
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _selectedCategory == null,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = null),
                              ),
                              const SizedBox(width: 8),
                              ...categories.map((cat) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(cat),
                                      selected: _selectedCategory == cat,
                                      onSelected: (_) => setState(
                                          () => _selectedCategory = cat),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (goals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyStateWidget(
                            icon: Icons.flag_rounded,
                            title: 'No goals yet',
                            subtitle: 'Set your first goal and start tracking progress',
                            actionLabel: 'Add Goal',
                            onAction: _showAddGoalDialog,
                          ),
                        )
                      else
                        ...() {
                          final filtered = _selectedCategory == null
                              ? goals
                              : goals
                                  .where((g) => g.category == _selectedCategory)
                                  .toList();

                          final grouped = <String, List<GoalModel>>{};
                          for (final g in filtered) {
                            grouped.putIfAbsent(g.category, () => []).add(g);
                          }

                          return grouped.entries.map((entry) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CategoryHeader(category: entry.key),
                                  const SizedBox(height: 10),
                                  ...entry.value.map((goal) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _GoalCard(goal: goal),
                                      )),
                                  const SizedBox(height: 14),
                                ],
                              ));
                        }(),
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

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          category,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  Color get _priorityColor {
    switch (goal.priority.toLowerCase()) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      default:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.progress.clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primaryContainer,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Due ${DateFormat('MMM d, y').format(goal.targetDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _StatusBadge(status: goal.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'in_progress':
        color = AppColors.primary;
        break;
      case 'overdue':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
