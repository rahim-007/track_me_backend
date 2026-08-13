import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../providers/ai_provider.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('AI Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(aiInsightsProvider),
          ),
        ],
      ),
      body: insightsAsync.when(
        data: (insights) => _InsightsBody(insights: insights),
        loading: () => const _InsightsSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  final AiInsightsModel insights;

  const _InsightsBody({required this.insights});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Productivity Score Card
              _ProductivityScoreCard(score: insights.productivityScore),

              const SizedBox(height: 20),

              // Weekly Report
              _SectionTitle(title: '📊 Weekly Report'),
              const SizedBox(height: 10),
              AppCard(
                child: Text(
                  insights.weeklyReport,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Habit Analysis
              _SectionTitle(title: '🔍 Habit Analysis'),
              const SizedBox(height: 10),
              _HabitAnalysisCard(
                strengths: insights.strengths,
                weaknesses: insights.weaknesses,
              ),

              const SizedBox(height: 20),

              // Recommendations
              _SectionTitle(title: '💡 Recommendations'),
              const SizedBox(height: 10),
              ...insights.recommendations.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecommendationCard(
                    index: entry.key + 1,
                    text: entry.value,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // AI Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Powered by Google Gemini AI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProductivityScoreCard extends StatelessWidget {
  final int score;
  const _ProductivityScoreCard({required this.score});

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreLabel {
    if (score >= 80) return 'Excellent!';
    if (score >= 60) return 'Good Progress';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity Score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scoreLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            progress: score / 100,
            size: 90,
            strokeWidth: 8,
            color: Colors.white,
            centerWidget: Text(
              '${score}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitAnalysisCard extends StatelessWidget {
  final List<String> strengths;
  final List<String> weaknesses;

  const _HabitAnalysisCard({
    required this.strengths,
    required this.weaknesses,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _AnalysisSection(
            title: 'Strengths 💪',
            items: strengths,
            color: AppColors.success,
            icon: Icons.thumb_up_rounded,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _AnalysisSection(
            title: 'Areas to Improve 🎯',
            items: weaknesses,
            color: AppColors.warning,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  const _AnalysisSection({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final int index;
  final String text;

  const _RecommendationCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ShimmerBox(height: 140, borderRadius: 20),
          const SizedBox(height: 20),
          const ShimmerBox(height: 100, borderRadius: 16),
          const SizedBox(height: 20),
          const ShimmerBox(height: 180, borderRadius: 16),
          const SizedBox(height: 20),
          const ShimmerBox(height: 70, borderRadius: 16),
        ],
      ),
    );
  }
}
