import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/goal_units.dart';
import '../../../habits/data/quotes_data.dart';
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
    _quoteIndex = Random().nextInt(kHabitQuotes.length);
  }

  void _nextQuote() {
    setState(() {
      int next;
      do {
        next = Random().nextInt(kHabitQuotes.length);
      } while (next == _quoteIndex && kHabitQuotes.length > 1);
      _quoteIndex = next;
    });
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddGoalDialog(),
    );
  }

  Widget _buildHighlightedQuote(String text) {
    final highlightWords = [
      'habit', 'habits', 'routine', 'routines', 'consistency', 'discipline',
      'well-being', 'choices', 'investment', 'health', 'care', 'natural', 'body', 'rest',
      'goal', 'goals', 'progress', 'strong', 'future', 'practice', 'small', 'healthy',
      'protect', 'responds', 'move', 'ordinary', 'easier', 'investment', 'living'
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

  @override
  Widget build(BuildContext context) {
    // Watch themeProvider to adapt UI when Dark / Light mode toggles
    ref.watch(themeProvider);
    final isDark = AppColors.isDarkMode;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
            color: const Color(0xFF5334EA),
            gradient: const LinearGradient(
              colors: [Color(0xFF6849F7), Color(0xFF4325D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5334EA).withOpacity(0.4),
                blurRadius: 16,
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
            // Distinct categories present in actual goals data
            final categories = goals
                .map((g) => g.category)
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();

            final filteredGoals = _selectedCategory == null
                ? goals
                : goals.where((g) => g.category == _selectedCategory).toList();

            final completedCount = goals.where((g) => g.status == 'completed' || g.progress >= 1.0).length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── 1. Header (Very Top) ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Goal Tracker 🎯',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Turn intentions into progress.',
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
                        // Filter Toggle Button
                        GestureDetector(
                          onTap: () {
                            // Cycle through categories or clear filter
                            setState(() {
                              if (_selectedCategory == null && categories.isNotEmpty) {
                                _selectedCategory = categories.first;
                              } else {
                                _selectedCategory = null;
                              }
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B162C) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A2244) : const Color(0xFFE8E2FC),
                              ),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _selectedCategory != null
                                  ? const Color(0xFF5334EA)
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 2. Quote Hero Banner Card (Below Header) ───────────────
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
                              final currentQuote = kHabitQuotes[_quoteIndex];
                              final cleanAuthor = currentQuote.author
                                  .replaceAll('Inspired by ', '')
                                  .trim();

                              return Stack(
                                children: [
                                  // Background Hero Banner Graphic (Artwork with Climber on Right)
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/goal_hero_banner.png',
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



                // ─── 3. Filter Chips System ─────────────────────────────────
                if (categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _FilterChipPill(
                            label: 'All',
                            icon: Icons.check_circle_outline_rounded,
                            isSelected: _selectedCategory == null,
                            onTap: () => setState(() => _selectedCategory = null),
                          ),
                          const SizedBox(width: 8),
                          ...categories.map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChipPill(
                                label: cat,
                                isSelected: _selectedCategory == cat,
                                onTap: () => setState(() => _selectedCategory = cat),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ─── 4. Active Goals Header ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Active Goals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5334EA).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filteredGoals.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5334EA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$completedCount / ${goals.length} Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // ─── 5. Goals List / Empty State ─────────────────────────────
                if (filteredGoals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B162C) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A2244) : const Color(0xFFE8E2FC),
                          ),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'No goals yet?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add a new goal and keep moving forward.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddGoalDialog,
                              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              label: const Text(
                                'Create Goal',
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5334EA),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = filteredGoals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GoalCard(goal: goal),
                          );
                        },
                        childCount: filteredGoals.length,
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

// ─── Filter Chip Pill Widget ──────────────────────────────────────────────────

class _FilterChipPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5334EA)
              : (isDark ? const Color(0xFF1B162C) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5334EA)
                : (isDark ? const Color(0xFF2A2244) : const Color(0xFFE8E2FC)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5334EA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white.withOpacity(0.8) : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Redesigned Goal Card ────────────────────────────────────────────

class _GoalCard extends ConsumerWidget {
  final GoalModel goal;
  const _GoalCard({required this.goal});

  Color get _priorityColor {
    switch (goal.priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color get _categoryColor {
    switch (goal.category.toLowerCase()) {
      case 'finance':
        return const Color(0xFF10B981);
      case 'fitness':
      case 'health':
        return const Color(0xFF5334EA);
      case 'education':
      case 'career':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return '💰';
      case 'fitness':
      case 'health':
        return '💪';
      case 'education':
      case 'career':
        return '📖';
      case 'personal':
        return '🎯';
      default:
        return '🚀';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode;
    final progress = goal.progress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final isCompleted = goal.status.toLowerCase() == 'completed' || progress >= 1.0;

    // Remaining days calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);
    final daysLeft = target.difference(today).inDays;

    String daysText;
    if (daysLeft > 0) {
      daysText = '$daysLeft days left';
    } else if (daysLeft == 0) {
      daysText = 'Due today';
    } else {
      daysText = '${daysLeft.abs()} days overdue';
    }

    return GestureDetector(
      onTap: () => _showManageGoalSheet(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B162C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2244) : const Color(0xFFE8E2FC),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF5334EA).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left Category Accent Vertical Bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: isCompleted ? const Color(0xFF10B981) : _categoryColor,
                ),
              ),
              // Content Inner Container
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Pill Left | Priority Badge Right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: _categoryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getCategoryEmoji(goal.category), style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                goal.category,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Priority Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goal.priority,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Progress Section: Track Bar + Percentage
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: progress),
                              builder: (context, animVal, _) {
                                return LinearProgressIndicator(
                                  value: animVal,
                                  backgroundColor: isDark
                                      ? const Color(0xFF281E48)
                                      : const Color(0xFFEADBFF),
                                  valueColor: AlwaysStoppedAnimation(
                                    isCompleted ? const Color(0xFF10B981) : const Color(0xFF5334EA),
                                  ),
                                  minHeight: 7,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF5334EA),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom Row: Due Date + Days Left | Status Pill + Arrow Affordance
                    Row(
                      children: [
                        // Calendar Icon + Due Date + Remaining Days
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Due ${DateFormat('MMM d, y').format(goal.targetDate)} • $daysText',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: daysLeft < 0 ? const Color(0xFFEF4444) : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Pill
                        _StatusBadge(status: isCompleted ? 'completed' : goal.status),

                        const SizedBox(width: 8),

                        // Circular Navigation Arrow Affordance ->
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (isCompleted ? const Color(0xFF10B981) : const Color(0xFF5334EA)).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF5334EA),
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
      ),
    );
  }

  bool _isFinancialGoal(String name, String category) {
    final cat = category.toLowerCase();
    if (cat == 'finance') return true;

    final cleanName = name.toLowerCase();
    if (cleanName.contains(r'$') ||
        cleanName.contains('₹') ||
        cleanName.contains('€') ||
        cleanName.contains('£')) {
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

                        // Quick Increment Buttons Row
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

                        // Edit Goal
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
        return 'Small steps today, big freedom tomorrow. 💰';
      case 'fitness':
        return 'Stronger every day! You\'ve got this! 🔥';
      case 'education':
        return 'Knowledge is power. Keep learning! 📖';
      case 'personal':
        return 'Invest in yourself. You are worth it! 🌟';
      default:
        return 'Every action counts. Keep moving forward! 🚀';
    }
  }

  Map<String, dynamic> _parseGoalDetails(String category, double progress) {
    final isFinance = category.toLowerCase() == 'finance';
    String prefix = '';
    String suffix = '';
    double target;
    bool allowsDecimals;
    double step;

    if (goal.hasTarget) {
      target = goal.target;
      final unit = goal.unit.trim();
      if (unit.isEmpty) {
        if (isFinance) prefix = '₹';
      } else if (isCurrencyUnitSymbol(unit)) {
        prefix = unit;
      } else {
        suffix = ' $unit';
      }
    } else {
      final regex = RegExp(r'(\d[\d,]*)');
      final match = regex.firstMatch(goal.name);

      if (goal.name.contains('₹') || goal.name.contains(r'$')) {
        prefix = '₹';
      } else if (goal.name.contains('€')) {
        prefix = '€';
      } else if (goal.name.contains('£')) {
        prefix = '£';
      }

      if (match != null) {
        target = double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 100;
        if (isFinance && prefix.isEmpty) prefix = '₹';
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
        if (isFinance) prefix = '₹';
      }
    }

    final unit = goal.unit.trim();
    if (unit.isNotEmpty) {
      allowsDecimals = unitAllowsDecimals(unit);
      step = isCurrencyUnitSymbol(unit) ? 100 : (allowsDecimals ? 0.5 : 1);
    } else if (prefix.isNotEmpty) {
      allowsDecimals = false;
      step = 100;
    } else if (suffix.isNotEmpty) {
      allowsDecimals = true;
      step = 0.5;
    } else {
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
    if (prefix.isNotEmpty) return [100, 500, 1000];
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
      milestoneDesc = 'You are halfway there! Keep going! 💪';
    } else if (milestonePercent == 0.75) {
      milestoneTitle = suffix.isNotEmpty
          ? '${formatGoalValue(milestoneVal)} $suffix Milestone'
          : '${parsed['prefix']}${NumberFormat('#,##0').format(milestoneVal)} Milestone';
      milestoneDesc = 'Only ${_fmtValue(parsed, needed)} more to reach! 🚀';
    } else {
      milestoneTitle = suffix.isNotEmpty
          ? 'Complete ${formatGoalValue(target)} $suffix'
          : 'Reach ${parsed['prefix']}${NumberFormat('#,##0').format(target)} Goal';
      milestoneDesc = 'Almost done! You got this! 🔥';
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

// ─── Status Badge Widget ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF10B981);
        break;
      case 'in_progress':
        color = const Color(0xFF5334EA);
        break;
      case 'overdue':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = AppColors.textSecondary;
    }

    final displayText = status.toLowerCase() == 'in_progress' ? 'In Progress' : status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
