import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/goal_units.dart';
import '../../providers/goals_provider.dart';
import '../widgets/add_goal_dialog.dart';

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
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
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyStateWidget(
                icon: Icons.cloud_off_rounded,
                title: "Couldn't load goals",
                subtitle: 'Check your connection and try again',
                actionLabel: 'Try Again',
                onAction: () => ref.read(goalsProvider.notifier).loadGoals(),
              ),
            ),
          ),
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

    return GestureDetector(
      onTap: () => _showManageGoalSheet(context, ref),
      behavior: HitTestBehavior.opaque,
      child: AppCard(
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
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
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
      ),
    );
  }

  bool _isFinancialGoal(String name, String category) {
    final cat = category.toLowerCase();
    if (cat == 'finance') return true;

    final cleanName = name.toLowerCase();
    if (cleanName.contains(r'$') ||
        cleanName.contains('â‚¹') ||
        cleanName.contains('â‚¬') ||
        cleanName.contains('Â£')) {
      return true;
    }

    if (cleanName.startsWith('save') ||
        cleanName.startsWith('spend') ||
        cleanName.startsWith('earn') ||
        cleanName.startsWith('buy') ||
        cleanName.startsWith('budget')) {
      return true;
    }

    return false;
  }

  void _showManageGoalSheet(BuildContext context, WidgetRef ref) {
    final isFinance = _isFinancialGoal(goal.name, goal.category);
    final effectiveCategory = isFinance ? 'finance' : goal.category;
    double tempProgress = goal.progress;
    final themeColor = _getThemeColor(effectiveCategory);
    final parsed = _parseGoalDetails(effectiveCategory, tempProgress);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        // Drag Handle and Close button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceVariant,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                        
                        // Goal Title & Subtitle
                        Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMotivationalSubtitle(effectiveCategory),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Circular Progress Indicator
                        _buildCircularProgress(tempProgress, parsed, themeColor, effectiveCategory),
                        const SizedBox(height: 20),

                        // Update Section Header
                        Row(
                          children: [
                            Icon(
                              effectiveCategory.toLowerCase() == 'finance'
                                  ? Icons.account_balance_wallet_outlined
                                  : (effectiveCategory.toLowerCase() == 'fitness' 
                                      ? Icons.fitness_center_rounded 
                                      : Icons.trending_up_rounded),
                              color: themeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getUpdateLabel(effectiveCategory, parsed),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Selector Box (- Current +)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    final step = parsed['step'] as double;
                                    final current =
                                        (parsed['target'] as double) * tempProgress;
                                    final newVal = (current - step)
                                        .clamp(0.0, parsed['target'] as double);
                                    tempProgress = newVal / parsed['target'];
                                    parsed['current'] = newVal;
                                  });
                                },
                                icon: Icon(Icons.remove_rounded, color: AppColors.textSecondary),
                                style: IconButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppColors.border, width: 1.5),
                                  ),
                                  backgroundColor: AppColors.surface,
                                ),
                              ),
                              Text(
                                parsed['suffix'].toString().isNotEmpty
                                    ? '${formatGoalValue(parsed['current'])} ${parsed['suffix'].toString().trim()}'
                                    : (effectiveCategory.toLowerCase() == 'finance' 
                                        ? '${parsed['prefix']}${NumberFormat('#,##0').format(parsed['current'])}' 
                                        : '${formatGoalValue(parsed['current'])}%'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    final step = parsed['step'] as double;
                                    final current =
                                        (parsed['target'] as double) * tempProgress;
                                    final newVal = (current + step)
                                        .clamp(0.0, parsed['target'] as double);
                                    tempProgress = newVal / parsed['target'];
                                    parsed['current'] = newVal;
                                  });
                                },
                                icon: Icon(Icons.add_rounded, color: AppColors.textSecondary),
                                style: IconButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppColors.border, width: 1.5),
                                  ),
                                  backgroundColor: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quick Increment Buttons Row â€” amounts follow the unit
                        // type: money (100/500/1000), measurement (0.5/1/2.5),
                        // counts (1/5/10).
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _buildQuickActionButtons(
                            context,
                            _quickIncrements(parsed),
                            parsed,
                            tempProgress,
                            themeColor,
                            setModalState,
                            (newProgress) {
                              tempProgress = newProgress;
                            },
                            effectiveCategory,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Next Milestone Section
                        _buildMilestoneCard(tempProgress, parsed, themeColor),
                        const SizedBox(height: 20),

                        // Stats Grid Row (Target, Due, Record, Left)
                        _buildStatsGrid(parsed, themeColor, effectiveCategory),
                        const SizedBox(height: 24),

                        // Edit Goal â€” opens the goal form pre-filled with the
                        // current values.
                        AppButton.outlined(
                          label: 'Edit Goal',
                          icon: Icons.edit_rounded,
                          foregroundColor: themeColor,
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => AddGoalDialog(goal: goal),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Save Button
                        AppButton(
                          label: 'Save Progress',
                          backgroundColor: themeColor,
                          onPressed: () {
                            ref.read(goalsProvider.notifier).updateProgress(goal.id, tempProgress);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Delete Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: AppColors.isDarkMode ? const Color(0xFF3B1E1E) : AppColors.errorLight.withOpacity(0.3),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmationDialog(context, ref);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text(
                              'Delete Goal',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getUpdateLabel(String category, Map<String, dynamic> parsed) {
    final suffix = parsed['suffix'].toString().trim();
    if (suffix.isNotEmpty) {
      return 'Update $suffix';
    }

    final cat = category.toLowerCase();
    if (cat == 'finance') {
      return 'Update Amount';
    }
    if (cat == 'fitness') {
      return 'Update Reps';
    }
    return 'Update Progress';
  }

  Color _getThemeColor(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return AppColors.success;
      case 'fitness':
        return AppColors.primary;
      case 'education':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }

  String _getMotivationalSubtitle(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return 'Small steps today, big freedom tomorrow. ðŸ’°';
      case 'fitness':
        return 'Stronger every day! You\'ve got this! ðŸ”¥';
      case 'education':
        return 'Knowledge is power. Keep learning! ðŸŽ“';
      case 'personal':
        return 'Invest in yourself. You are worth it! ðŸŒŸ';
      default:
        return 'Every action counts. Keep moving forward! ðŸš€';
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return 'ðŸ’°';
      case 'fitness':
        return 'ðŸ’ª';
      case 'education':
        return 'ðŸ“š';
      case 'health':
        return 'ðŸ¥—';
      case 'relationships':
        return 'â¤ï¸';
      case 'personal':
        return 'ðŸŽ¯';
      default:
        return 'ðŸš€';
    }
  }

  /// Resolves the numeric target/unit of this goal for the progress UI.
  ///
  /// Stored `target`/`unit` fields (added with the type-aware tracker) take
  /// precedence; legacy goals without them fall back to parsing the target out
  /// of the goal name, exactly as before.
  Map<String, dynamic> _parseGoalDetails(String category, double progress) {
    final isFinance = category.toLowerCase() == 'finance';
    String prefix = '';
    String suffix = '';
    double target;
    bool allowsDecimals;
    double step;

    if (goal.hasTarget) {
      // Modern goals carry an explicit target + unit.
      target = goal.target;
      final unit = goal.unit.trim();
      if (unit.isEmpty) {
        if (isFinance) prefix = 'â‚¹';
      } else if (isCurrencyUnitSymbol(unit)) {
        prefix = unit; // â‚¹50,000 â†’ shown as a prefix
      } else {
        suffix = ' $unit'; // 5 kg â†’ shown as a suffix
      }
    } else {
      // Legacy goal â€” infer target/unit from the name (previous behavior).
      final regex = RegExp(r'(\d[\d,]*)');
      final match = regex.firstMatch(goal.name);

      if (goal.name.contains('â‚¹') || goal.name.contains(r'$')) {
        prefix = 'â‚¹';
      } else if (goal.name.contains('â‚¬')) {
        prefix = 'â‚¬';
      } else if (goal.name.contains('Â£')) {
        prefix = 'Â£';
      }

      if (match != null) {
        target = double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 100;
        if (isFinance && prefix.isEmpty) prefix = 'â‚¹';
        if (!isFinance) {
          final index = goal.name.indexOf(match.group(0)!);
          if (index != -1) {
            final rest =
                goal.name.substring(index + match.group(0)!.length).trim();
            if (rest.isNotEmpty) suffix = ' $rest';
          }
        }
      } else {
        target = isFinance ? 10000 : 100;
        if (isFinance) prefix = 'â‚¹';
      }
    }

    // Input rules follow the unit type: measurement â†’ decimals + 0.5 steps,
    // money â†’ whole numbers + 100 steps, counts â†’ whole numbers + 1 steps.
    final unit = goal.unit.trim();
    if (unit.isNotEmpty) {
      allowsDecimals = unitAllowsDecimals(unit);
      step = isCurrencyUnitSymbol(unit) ? 100 : (allowsDecimals ? 0.5 : 1);
    } else if (prefix.isNotEmpty) {
      allowsDecimals = false;
      step = 100;
    } else if (suffix.isNotEmpty) {
      // Legacy measurement parsed from the name (e.g. "Lose 5 kg") â€” decimals
      // and half-steps make sense.
      allowsDecimals = true;
      step = 0.5;
    } else {
      // No unit at all â€” permissive decimals, unit steps.
      allowsDecimals = true;
      step = 1;
    }

    final current = (target * progress).clamp(0.0, target);

    return {
      'target': target,
      'current': current,
      'prefix': prefix,
      'suffix': suffix,
      'allowsDecimals': allowsDecimals,
      'step': step,
    };
  }

  /// Formats [value] for display using the goal's resolved unit:
  /// '0.5 kg', 'â‚¹50,000', '2.75 km', '5' (no unit).
  String _fmtValue(Map<String, dynamic> parsed, num value) {
    final suffix = parsed['suffix'].toString().trim();
    final prefix = parsed['prefix'].toString();
    if (suffix.isNotEmpty) {
      return '${formatGoalValue(value)} $suffix';
    }
    if (prefix.isNotEmpty) {
      return '$prefix${NumberFormat('#,##0').format(value)}';
    }
    return formatGoalValue(value);
  }

  Widget _buildCircularProgress(double progress, Map<String, dynamic> parsed, Color themeColor, String category) {
    final currentStr = _fmtValue(parsed, parsed['current']);
    final targetStr = _fmtValue(parsed, parsed['target']);

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 156,
            height: 156,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: themeColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getCategoryEmoji(category),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                parsed['suffix'].toString().isNotEmpty
                    ? formatGoalValue(parsed['current'])
                    : currentStr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                parsed['suffix'].toString().isNotEmpty
                    ? '/ ${formatGoalValue(parsed['target'])}${parsed['suffix']}'
                    : 'of $targetStr',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<num> _quickIncrements(Map<String, dynamic> parsed) {
    final prefix = parsed['prefix'].toString();
    if (prefix.isNotEmpty) return [100, 500, 1000]; // money
    return (parsed['allowsDecimals'] as bool) ? [0.5, 1, 2.5] : [1, 5, 10];
  }

  List<Widget> _buildQuickActionButtons(
    BuildContext context,
    List<num> increments,
    Map<String, dynamic> parsed,
    double progress,
    Color themeColor,
    StateSetter setModalState,
    Function(double) onUpdated,
    String category,
  ) {
    final isFinance = category.toLowerCase() == 'finance';
    final list = <Widget>[];

    for (final inc in increments) {
      list.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: OutlinedButton(
              onPressed: () {
                setModalState(() {
                  final current = (parsed['target'] as double) * progress;
                  final newVal =
                      (current + inc).clamp(0.0, parsed['target'] as double);
                  onUpdated(newVal / parsed['target']);
                  parsed['current'] = newVal;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: themeColor.withOpacity(0.2), width: 1.5),
                backgroundColor: themeColor.withOpacity(0.04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isFinance
                    ? '+ ${parsed['prefix']}${formatGoalValue(inc)}'
                    : '+ ${formatGoalValue(inc)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    list.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showCustomInputDialog(context, parsed, progress, setModalState, onUpdated),
          icon: Icon(Icons.edit_note_rounded, size: 16, color: themeColor),
          label: Text(
            'Custom',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: themeColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: themeColor.withOpacity(0.2), width: 1.5),
            backgroundColor: themeColor.withOpacity(0.04),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );

    return list;
  }

  void _showCustomInputDialog(
    BuildContext context,
    Map<String, dynamic> parsed,
    double progress,
    StateSetter setModalState,
    Function(double) onUpdated,
  ) {
    final allowsDecimals = parsed['allowsDecimals'] as bool;
    final suffix = parsed['suffix'].toString().trim();
    final prefix = parsed['prefix'].toString();
    final controller =
        TextEditingController(text: formatGoalValue(parsed['current']));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Enter Custom Value', style: TextStyle(color: AppColors.onSurface)),
        content: TextField(
          controller: controller,
          keyboardType: allowsDecimals
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              final pattern =
                  allowsDecimals ? decimalValuePattern : integerValuePattern;
              return pattern.hasMatch(newValue.text) ? newValue : oldValue;
            }),
          ],
          autofocus: true,
          style: TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            labelText: suffix.isNotEmpty
                ? 'Current $suffix'
                : (prefix.isNotEmpty ? 'Amount' : 'Current value'),
            prefixText: prefix,
            labelStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.replaceAll(',', '');
              final val =
                  allowsDecimals ? double.tryParse(text) : int.tryParse(text);
              if (val != null) {
                setModalState(() {
                  final cleanVal =
                      val.clamp(0.0, parsed['target'] as double);
                  onUpdated(cleanVal / parsed['target']);
                  parsed['current'] = cleanVal;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(double progress, Map<String, dynamic> parsed, Color themeColor) {
    final target = parsed['target'] as double;
    final current = (target * progress).clamp(0.0, target);
    final suffix = parsed['suffix'].toString().trim();

    double milestonePercent = 0.5;
    if (progress >= 0.5 && progress < 0.75) {
      milestonePercent = 0.75;
    } else if (progress >= 0.75) {
      milestonePercent = 1.0;
    }

    final milestoneVal = target * milestonePercent;
    final needed = (milestoneVal - current).clamp(0.0, milestoneVal);

    String milestoneTitle = '';
    String milestoneDesc = '';

    if (milestonePercent == 0.5) {
      milestoneTitle = suffix.isNotEmpty
          ? '${formatGoalValue(milestoneVal)} $suffix Milestone'
          : '${parsed['prefix']}${NumberFormat('#,##0').format(milestoneVal)} Milestone';
      milestoneDesc = 'You are halfway there! Keep going! ðŸ’ª';
    } else if (milestonePercent == 0.75) {
      milestoneTitle = suffix.isNotEmpty
          ? '${formatGoalValue(milestoneVal)} $suffix Milestone'
          : '${parsed['prefix']}${NumberFormat('#,##0').format(milestoneVal)} Milestone';
      milestoneDesc = 'Only ${_fmtValue(parsed, needed)} more to reach! ðŸš€';
    } else {
      milestoneTitle = suffix.isNotEmpty
          ? 'Complete ${formatGoalValue(target)} $suffix'
          : 'Reach ${parsed['prefix']}${NumberFormat('#,##0').format(target)} Goal';
      milestoneDesc = 'Almost done! You got this! ðŸ”¥';
    }

    final milestoneProgress = (current / milestoneVal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: themeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Milestone',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestoneTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  milestoneDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: milestoneProgress,
                    minHeight: 6,
                    backgroundColor: themeColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(themeColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> parsed, Color themeColor, String category) {
    final targetStr = _fmtValue(parsed, parsed['target']);
    final currentStr = _fmtValue(parsed, parsed['current']);
    final leftStr = _fmtValue(
      parsed,
      (parsed['target'] - parsed['current']).clamp(0.0, parsed['target'] as double),
    );
    final isFinance = category.toLowerCase() == 'finance';

    return Row(
      children: [
        _buildStatCard('Target', targetStr, Icons.track_changes_rounded),
        const SizedBox(width: 8),
        _buildStatCard('Due Date', DateFormat('MMM d, y').format(goal.targetDate), Icons.calendar_today_rounded),
        const SizedBox(width: 8),
        _buildStatCard(
          isFinance ? 'Saved' : 'Record',
          currentStr,
          isFinance ? Icons.account_balance_wallet_rounded : Icons.star_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatCard('Left to Go', leftStr, Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
             Icon(icon, size: 16, color: AppColors.textSecondary),
             const SizedBox(height: 6),
             Text(
               label,
               style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 2),
             Text(
               value,
               style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
               textAlign: TextAlign.center,
             ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Goal', style: TextStyle(color: AppColors.onSurface)),
        content: Text(
          'Are you sure you want to delete "${goal.name}"? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(goalsProvider.notifier).deleteGoal(goal.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
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
