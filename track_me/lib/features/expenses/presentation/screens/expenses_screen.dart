import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' show ImageFilter;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/models/expense_category.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/extra_income_provider.dart';
import '../../providers/expense_analytics_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../widgets/bento_finance_grid.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_expense_sheet.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(budgetProvider.notifier).loadCurrentBudget();
    });
  }

  void _showAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        onSave: (expense) async {
          await ref.read(expensesListProvider.notifier).addExpense(expense);
          ref.read(expenseDashboardProvider.notifier).reload();
          ref.read(expenseAnalyticsProvider.notifier).reload();
        },
      ),
    );
  }

  String getGreeting(String? name) {
    final hour = DateTime.now().hour;
    final String greetingText;
    if (hour < 12) {
      greetingText = 'Good Morning';
    } else if (hour < 17) {
      greetingText = 'Good Afternoon';
    } else {
      greetingText = 'Good Evening';
    }
    return name != null ? '$greetingText, $name 👋' : '$greetingText 👋';
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final dashboardState = ref.watch(expenseDashboardProvider);
    final analyticsState = ref.watch(expenseAnalyticsProvider);
    final selectedFilter = ref.watch(expenseFilterProvider);
    final extraIncomeTotal = ref.watch(extraIncomeTotalProvider);
    final extraIncomeCount = ref.watch(extraIncomeCountProvider);

    return budgetState.when(
      skipLoadingOnRefresh: true,
      loading: () => _buildLoading(),
      error: (_, __) => _buildLoading(),
      data: (budget) {
        if (budget == null) {
          return _buildNoBudgetView();
        }
        return dashboardState.when(
          skipLoadingOnRefresh: true,
          loading: () => _buildLoading(),
          error: (_, __) => _buildDashboard(
            budget: budget,
            dashboard: null,
            analytics: null,
            selectedFilter: selectedFilter,
            extraIncomeTotal: extraIncomeTotal,
            extraIncomeCount: extraIncomeCount,
          ),
          data: (dashboard) => analyticsState.when(
            skipLoadingOnRefresh: true,
            loading: () => _buildLoading(),
            error: (_, __) => _buildDashboard(
              budget: budget,
              dashboard: dashboard,
              analytics: null,
              selectedFilter: selectedFilter,
              extraIncomeTotal: extraIncomeTotal,
              extraIncomeCount: extraIncomeCount,
            ),
            data: (analytics) => _buildDashboard(
              budget: budget,
              dashboard: dashboard,
              analytics: analytics,
              selectedFilter: selectedFilter,
              extraIncomeTotal: extraIncomeTotal,
              extraIncomeCount: extraIncomeCount,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildNoBudgetView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3F0FF), Color(0xFFEBE5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: const Text('💰', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 28),
                Text(
                  'Set Up Your Budget',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Configure your monthly income and savings\ntarget to start tracking your cash flow.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.expenseSetup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: AppColors.primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard({
    required dynamic budget,
    DashboardData? dashboard,
    AnalyticsData? analytics,
    required ExpenseFilterType selectedFilter,
    double extraIncomeTotal = 0,
    int extraIncomeCount = 0,
  }) {
    final todayTotal = dashboard?.today.total ?? 0.0;
    final dailyGoal = dashboard?.today.dailyGoal ?? budget.dailyGoal ?? 0.0;
    final profitLoss = dailyGoal - todayTotal;

    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpense,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(budgetProvider.notifier).loadCurrentBudget();
            ref.read(expenseDashboardProvider.notifier).reload();
            ref.read(expenseAnalyticsProvider.notifier).reload();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(profileState.value?.name),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Track your money. Build your future.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  PopupMenuButton<ExpenseFilterType>(
                    initialValue: selectedFilter,
                    onSelected: (filter) async {
                      if (filter == ExpenseFilterType.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          ref.read(expenseCustomRangeProvider.notifier).state = picked;
                          ref.read(expenseFilterProvider.notifier).state = filter;
                        }
                      } else {
                        ref.read(expenseFilterProvider.notifier).state = filter;
                      }
                    },
                    itemBuilder: (context) => ExpenseFilterType.values.map((type) {
                      return PopupMenuItem<ExpenseFilterType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            selectedFilter.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.expenseAnalytics),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Today's Hero
                    _TodayHeroCard(
                      todayTotal: todayTotal,
                      dailyGoal: dailyGoal,
                      profitLoss: profitLoss,
                    ),
                    const SizedBox(height: 16),

                    // Bento Finance Grid
                    BentoFinanceGrid(
                      monthlyIncome: budget.monthlyIncome,
                      savingsTarget: budget.savingsTarget,
                      spendableBudget: budget.spendableBudget,
                      dailyGoal: dailyGoal,
                      todayTotal: todayTotal,
                      savingsProgress: dashboard?.month.savingsProgress ?? 0.0,
                      savingsRate: dashboard?.month.savingsRate ?? 0.0,
                      monthlyProfit: dashboard?.month.monthlyProfit ?? 0.0,
                      monthlyLoss: dashboard?.month.monthlyLoss ?? 0.0,
                      extraIncomeTotal: extraIncomeTotal,
                      extraIncomeCount: extraIncomeCount,
                      onExtraIncomeTap: () => context.push(AppRoutes.extraIncome),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions Section
                    _QuickActionsRow(
                      onAddExpense: _showAddExpense,
                      onBudget: () => context.push(AppRoutes.expenseSetup),
                      onExtraIncome: () => context.push(AppRoutes.extraIncome),
                      onReports: () => context.push(AppRoutes.expenseAnalytics),
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    _SectionHeader(
                      title: 'Recent Transactions',
                      onViewAll: dashboard != null && dashboard.recentTransactions.isNotEmpty
                          ? () => context.push(AppRoutes.allTransactions)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (dashboard == null || dashboard.recentTransactions.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.receipt_long_rounded,
                        title: 'No transactions yet',
                        subtitle: 'Add your first expense to start tracking',
                      )
                    else
                      ...dashboard.recentTransactions.take(3).map(
                        (exp) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TransactionCard(
                            expense: exp,
                            onTap: () => context.push(AppRoutes.expenseDetail, extra: exp),
                            onDelete: () async {
                              await ref.read(expensesListProvider.notifier).deleteExpense(exp.id);
                              ref.read(expenseDashboardProvider.notifier).reload();
                              ref.read(expenseAnalyticsProvider.notifier).reload();
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Spending by Category Donut Chart
                    if (analytics != null) ...[
                      _CategoryDonutCard(analytics: analytics),
                      const SizedBox(height: 24),
                    ],

                    // Daily Expense Goal Chart
                    if (analytics != null) ...[
                      _DailyExpenseGoalChart(analytics: analytics, dailyGoal: dailyGoal),
                      const SizedBox(height: 24),
                    ],

                    // Monthly Spending Trend
                    if (analytics != null) ...[
                      _MonthlySpendingTrend(
                        analytics: analytics,
                        spendableBudget: budget.spendableBudget,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Edit Budget Button
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.expenseSetup),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.settings_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Budget Settings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Update your income, target date, or limits',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Today's Hero Card ──────────────────────────────────────────────────────

class _TodayHeroCard extends StatelessWidget {
  final double todayTotal;
  final double dailyGoal;
  final double profitLoss;

  const _TodayHeroCard({
    required this.todayTotal,
    required this.dailyGoal,
    required this.profitLoss,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = todayTotal <= dailyGoal;
    final progress = dailyGoal > 0 ? (todayTotal / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background container with premium gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Premium purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date & glassmorphic status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.today_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: Colors.white.withOpacity(0.15),
                          child: Text(
                            isProfit ? '🟢 On Track' : '🔴 Overspent',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Main spending row: Large amount & Remaining budget
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S SPENDING",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${NumberFormat('#,##0').format(todayTotal)}',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "REMAINING",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${NumberFormat('#,##0').format((dailyGoal - todayTotal).clamp(0.0, double.infinity))}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isProfit ? Colors.white : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Thicker, modern progress bar with a custom look
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isProfit ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5), // lighter
                              isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444), // base
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: (isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Bottom Budget & Streak stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Limit: ₹${NumberFormat('#,##0').format(dailyGoal)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      isProfit
                          ? 'Remaining today: ₹${NumberFormat('#,##0').format(profitLoss.abs())}'
                          : 'Over today: ₹${NumberFormat('#,##0').format(profitLoss.abs())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Abstract background decoration shapes
          Positioned(
            right: -30,
            top: -20,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Row ──────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onBudget;
  final VoidCallback onExtraIncome;
  final VoidCallback onReports;

  const _QuickActionsRow({
    required this.onAddExpense,
    required this.onBudget,
    required this.onExtraIncome,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Add Expense',
            color: const Color(0xFFEF4444),
            onTap: onAddExpense,
          ),
          _ActionButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Budget',
            color: const Color(0xFF7C3AED),
            onTap: onBudget,
          ),
          _ActionButton(
            icon: Icons.payments_outlined,
            label: 'Extra Income',
            color: const Color(0xFF8B5CF6),
            onTap: onExtraIncome,
          ),
          _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            color: const Color(0xFFF97316),
            onTap: onReports,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Spending by Category Donut Chart ───────────────────────────────────────

class _CategoryDonutCard extends StatelessWidget {
  final AnalyticsData analytics;

  const _CategoryDonutCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    double foodAmt = 0;
    double transportAmt = 0;
    double shoppingAmt = 0;
    double billsAmt = 0;
    double healthAmt = 0;
    double entertainmentAmt = 0;
    double othersAmt = 0;

    for (final item in analytics.categoryBreakdown) {
      final cat = ExpenseCategory.fromApi(item.category);
      switch (cat) {
        case ExpenseCategory.food:
          foodAmt += item.amount;
          break;
        case ExpenseCategory.transport:
          transportAmt += item.amount;
          break;
        case ExpenseCategory.shopping:
          shoppingAmt += item.amount;
          break;
        case ExpenseCategory.bills:
          billsAmt += item.amount;
          break;
        case ExpenseCategory.health:
          healthAmt += item.amount;
          break;
        case ExpenseCategory.entertainment:
          entertainmentAmt += item.amount;
          break;
        default:
          othersAmt += item.amount;
          break;
      }
    }

    final total = foodAmt + transportAmt + shoppingAmt + billsAmt + healthAmt + entertainmentAmt + othersAmt;

    final dataList = [
      _DonutSegment(name: 'Food', amount: foodAmt, color: const Color(0xFFF97316)),
      _DonutSegment(name: 'Transport', amount: transportAmt, color: const Color(0xFF3B82F6)),
      _DonutSegment(name: 'Shopping', amount: shoppingAmt, color: const Color(0xFF8B5CF6)),
      _DonutSegment(name: 'Bills', amount: billsAmt, color: const Color(0xFFEAB308)),
      _DonutSegment(name: 'Health', amount: healthAmt, color: const Color(0xFF10B981)),
      _DonutSegment(name: 'Entertainment', amount: entertainmentAmt, color: const Color(0xFFEC4899)),
      _DonutSegment(name: 'Others', amount: othersAmt, color: const Color(0xFF6B7280)),
    ].where((seg) => seg.amount > 0).toList();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No spending records for this month.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sections: dataList.map((seg) {
                            return PieChartSectionData(
                              value: seg.amount,
                              color: seg.color,
                              radius: 18,
                              showTitle: false,
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 42,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${NumberFormat('#,##0').format(total)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: dataList.map((seg) {
                      final pct = total > 0 ? (seg.amount / total) * 100 : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: seg.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seg.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  final String name;
  final double amount;
  final Color color;

  _DonutSegment({
    required this.name,
    required this.amount,
    required this.color,
  });
}

// ─── Daily Expense Goal Chart ───────────────────────────────────────────────

class _DailyExpenseGoalChart extends StatelessWidget {
  final AnalyticsData analytics;
  final double dailyGoal;

  const _DailyExpenseGoalChart({
    required this.analytics,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final last7Days = List.generate(7, (i) {
      return DateTime.now().subtract(Duration(days: 6 - i));
    });

    final barsData = last7Days.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final item = analytics.dailyBreakdown.firstWhere(
        (d) => d.date == dateKey,
        orElse: () => DailyBreakdown(date: dateKey, amount: 0.0),
      );
      
      final isToday = index == 6;
      final exceedsBudget = item.amount > dailyGoal;
      final barColor = exceedsBudget ? const Color(0xFFEF4444) : const Color(0xFF10B981);

      return _DailyBarData(
        index: index,
        dayLabel: DateFormat('E').format(date).substring(0, 1),
        amount: item.amount,
        color: barColor,
        isToday: isToday,
      );
    }).toList();

    final maxVal = barsData.fold<double>(dailyGoal, (max, d) => d.amount > max ? d.amount : max);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Spending vs. Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Daily budget limit: ₹${NumberFormat('#,##0').format(dailyGoal)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barGroups: barsData.map((d) {
                  return BarChartGroupData(
                    x: d.index,
                    barRods: [
                      BarChartRodData(
                        toY: d.amount,
                        color: d.color,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        borderSide: d.isToday
                            ? BorderSide(color: AppColors.primary, width: 2)
                            : BorderSide.none,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal * 1.25,
                          color: AppColors.isDarkMode ? const Color(0xFF2D2A3A) : const Color(0xFFF3F4F6),
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
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < barsData.length) {
                          final data = barsData[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data.dayLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: data.isToday ? FontWeight.w900 : FontWeight.w600,
                                  color: data.isToday ? AppColors.primary : AppColors.textSecondary),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBarData {
  final int index;
  final String dayLabel;
  final double amount;
  final Color color;
  final bool isToday;

  _DailyBarData({
    required this.index,
    required this.dayLabel,
    required this.amount,
    required this.color,
    required this.isToday,
  });
}

// ─── Monthly Spending Trend ──────────────────────────────────────────────────

class _MonthlySpendingTrend extends StatelessWidget {
  final AnalyticsData analytics;
  final double spendableBudget;

  const _MonthlySpendingTrend({
    required this.analytics,
    required this.spendableBudget,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysCount = now.day;
    double cumulativeSum = 0;
    final spots = <FlSpot>[];

    for (int day = 1; day <= daysCount; day++) {
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayAmount = analytics.dailyBreakdown.firstWhere(
        (d) => d.date == dateStr,
        orElse: () => DailyBreakdown(date: dateStr, amount: 0.0),
      ).amount;
      cumulativeSum += dayAmount;
      spots.add(FlSpot(day.toDouble(), cumulativeSum));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(1, 0));
    }

    final maxVal = cumulativeSum > spendableBudget ? cumulativeSum : spendableBudget;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spending Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current spendable budget: ₹${NumberFormat('#,##0').format(spendableBudget)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                maxY: maxVal * 1.2,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final day = val.toInt();
                        if (day == 1 || day == 10 || day == 20 || day == 30 || day == daysCount) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Day $day',
                              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: spendableBudget,
                      color: const Color(0xFFEF4444).withOpacity(0.6),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                        ),
                        labelResolver: (line) => 'Limit: ₹${NumberFormat('#,##0').format(spendableBudget)}',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text('View All →', style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}
