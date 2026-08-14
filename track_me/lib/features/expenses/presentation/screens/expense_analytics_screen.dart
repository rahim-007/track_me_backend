import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/expense_category.dart';
import '../../providers/expense_analytics_provider.dart';

class ExpenseAnalyticsScreen extends ConsumerStatefulWidget {
  const ExpenseAnalyticsScreen({super.key});

  @override
  ConsumerState<ExpenseAnalyticsScreen> createState() =>
      _ExpenseAnalyticsScreenState();
}

class _ExpenseAnalyticsScreenState
    extends ConsumerState<ExpenseAnalyticsScreen> {
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(expenseAnalyticsProvider.notifier)
          .loadAnalytics(period: _selectedPeriod);
    });
  }

  void _changePeriod(String period) {
    setState(() => _selectedPeriod = period);
    ref.read(expenseAnalyticsProvider.notifier).loadAnalytics(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(expenseAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child:
                Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          // Period Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['weekly', 'monthly', 'yearly'].map((p) {
                  final isActive = p == _selectedPeriod;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _changePeriod(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 6,
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: analyticsState.when(
              skipLoadingOnRefresh: true,
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Center(child: Text('Error loading analytics')),
              data: (data) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Spent',
                            value: '₹${NumberFormat('#,##0').format(data.totalAmount)}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Transactions',
                            value: '${data.transactionCount}',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Daily Avg',
                            value: '₹${NumberFormat('#,##0').format(data.dailyAverage)}',
                            color: const Color(0xFFF97316),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category Pie Chart
                    if (data.categoryBreakdown.isNotEmpty) ...[
                      Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CategoryPieChart(
                          categories: data.categoryBreakdown,
                          totalAmount: data.totalAmount),
                      const SizedBox(height: 24),
                    ],

                    // Daily Bar Chart
                    if (data.dailyBreakdown.isNotEmpty) ...[
                      Text(
                        'Daily Spending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DailyBarChart(days: data.dailyBreakdown),
                      const SizedBox(height: 24),
                    ],

                    // Category List
                    if (data.categoryBreakdown.isNotEmpty) ...[
                      Text(
                        'Category Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.categoryBreakdown.map((c) {
                        final cat = ExpenseCategory.fromApi(c.category);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.lightColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(cat.emoji,
                                        style: const TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: c.percentage / 100,
                                          minHeight: 5,
                                          backgroundColor:
                                              cat.color.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation(
                                              cat.color),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${NumberFormat('#,##0').format(c.amount)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${c.percentage.toStringAsFixed(1)}%',
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
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Pie Chart ─────────────────────────────────────────────────────

class _CategoryPieChart extends StatelessWidget {
  final List<CategoryBreakdown> categories;
  final double totalAmount;

  const _CategoryPieChart({
    required this.categories,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: categories.take(6).map((c) {
              final cat = ExpenseCategory.fromApi(c.category);
              return PieChartSectionData(
                value: c.amount,
                title: '${c.percentage.toStringAsFixed(0)}%',
                color: cat.color,
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              );
            }).toList(),
            sectionsSpace: 3,
            centerSpaceRadius: 24,
          ),
        ),
      ),
    );
  }
}

// ─── Daily Bar Chart ────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<DailyBreakdown> days;

  const _DailyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final maxAmount = days.fold<double>(0, (max, d) => d.amount > max ? d.amount : max);

    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount * 1.2,
          barGroups: days.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.amount,
                  color: AppColors.primary,
                  width: days.length > 14 ? 6 : 12,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxAmount * 1.2,
                    color: AppColors.primary.withOpacity(0.06),
                  ),
                ),
              ],
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= days.length) return const SizedBox.shrink();
                  final date = days[idx].date;
                  // Show abbreviated label: day for daily/weekly/monthly
                  // series, month name for the monthly-aggregated yearly series.
                  final parts = date.split('-');
                  String dayStr;
                  if (parts.length >= 3) {
                    dayStr = parts[2];
                  } else if (parts.length == 2) {
                    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                    final month = int.tryParse(parts[1]) ?? 0;
                    dayStr = (month >= 1 && month <= 12) ? monthNames[month - 1] : date;
                  } else {
                    dayStr = date;
                  }
                  return Text(
                    dayStr,
                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
