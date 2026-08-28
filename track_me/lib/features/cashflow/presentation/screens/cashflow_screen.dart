import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/cashflow_models.dart';
import '../../providers/cashflow_provider.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/category_grid.dart';
import '../widgets/debt_ledger_sheet.dart';
import '../widgets/history_list.dart';
import '../widgets/setup_sheet.dart';

/// Which past period the user is inspecting, if any. Null = live month.
final _viewedPeriodIdProvider = StateProvider<String?>((_) => null);

/// Segment tab selection: 0 = Income (ESBI), 1 = Outflow (ESDI), 2 = Debt
final _cashFlowSegmentProvider = StateProvider<int>((_) => 0);

/// Cash Flow dashboard screen redesigned for 10/10 visual fidelity matching reference.
class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final isDark = AppColors.isDarkMode;
    final state = ref.watch(cashFlowProvider);
    final viewedId = ref.watch(_viewedPeriodIdProvider);
    final viewedPast =
        viewedId != null && viewedId != state.current.valueOrNull?.id;
    final period = viewedPast
        ? state.history.where((p) => p.id == viewedId).firstOrNull
        : state.current.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: viewedPast || period == null
          ? null
          : FloatingActionButton(
              onPressed: () => AddEntrySheet.show(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5848D6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6942FF), Color(0xFF4930D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5848D6).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(cashFlowProvider.notifier).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // ─── Top Header ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Flow',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Where your money comes from and where it goes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Toggle Button
                  GestureDetector(
                    onTap: () => _showFilterOptions(context, ref),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B162C) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
                        ),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add Entry Button (+)
                  if (!viewedPast)
                    GestureDetector(
                      onTap: () => AddEntrySheet.show(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5848D6),
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6942FF), Color(0xFF4930D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5848D6).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── Loaded Body ──────────────────────────────────────────────
              state.current.when(
                data: (_) => period == null
                    ? const SizedBox.shrink()
                    : _LoadedBody(period: period, viewedPast: viewedPast),
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => EmptyStateWidget(
                  icon: Icons.wifi_off_rounded,
                  title: 'Cash Flow unavailable',
                  subtitle:
                      'We could not reach the server. Your entries stay safe on this device.',
                  actionLabel: 'Retry',
                  onAction: () => ref.read(cashFlowProvider.notifier).load(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Cash Flow',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF5848D6)),
              title: const Text('All Entries'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981)),
              title: const Text('Inflow Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.trending_down_rounded, color: Color(0xFFF0445F)),
              title: const Text('Outflow Only'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _LoadedBody extends ConsumerWidget {
  final CashFlowPeriodModel period;
  final bool viewedPast;

  const _LoadedBody({required this.period, required this.viewedPast});

  bool get _isFresh =>
      period.totalIncome == 0 &&
      period.totalOutflow == 0 &&
      period.openingBank == 0 &&
      period.openingCash == 0 &&
      period.openingCreditCard == 0 &&
      period.openingDebt == 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashFlowProvider);
    final selectedSegment = ref.watch(_cashFlowSegmentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Net Cash Flow Hero Card (Reference Matched)
        _HeroFinancialCard(period: period),
        const SizedBox(height: 16),

        // 2. Month Selector Card
        _PeriodSelector(viewedPast: viewedPast),
        if (viewedPast) ...[
          const SizedBox(height: 10),
          _ReadOnlyBanner(onBack: () {
            ref.read(_viewedPeriodIdProvider.notifier).state = null;
            ref.read(cashFlowProvider.notifier).backToCurrent();
          }),
        ],
        if (!viewedPast && _isFresh) ...[
          const SizedBox(height: 10),
          _SetupPrompt(),
        ],
        const SizedBox(height: 20),

        // 3. Segmented Control Tabs (Income | Outflow | Debt)
        _CapsuleSegmentSlider(
          selectedIndex: selectedSegment,
          onTabSelected: (index) {
            ref.read(_cashFlowSegmentProvider.notifier).state = index;
          },
        ),
        const SizedBox(height: 20),

        // 4. Segment Dynamic Content
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              if (selectedSegment < 2) {
                ref.read(_cashFlowSegmentProvider.notifier).state = selectedSegment + 1;
              }
            } else if (details.primaryVelocity! > 200) {
              if (selectedSegment > 0) {
                ref.read(_cashFlowSegmentProvider.notifier).state = selectedSegment - 1;
              }
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(selectedSegment),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedSegment == 0) ...[
                    const _SectionTitle('INCOME CATEGORIES (ESBI)'),
                    const SizedBox(height: 10),
                    CategoryGrid(income: true, totals: period.incomeByCategory),
                  ] else if (selectedSegment == 1) ...[
                    const _SectionTitle('OUTFLOW CATEGORIES (ESDI)'),
                    const SizedBox(height: 10),
                    CategoryGrid(income: false, totals: period.outflowByCategory),
                  ] else ...[
                    const _SectionTitle('DEBT & RECEIVABLES'),
                    const SizedBox(height: 10),
                    _DebtSummaryTile(
                      yetToReceive: state.yetToReceive,
                      yetToGive: state.yetToGive,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 5. Transaction History List
        const _SectionTitle('THIS PERIOD TRANSACTIONS'),
        const SizedBox(height: 10),
        HistoryList(readOnly: viewedPast),
      ],
    );
  }
}

// ─── Segmented Control Tabs (Capsule Slider) ─────────────────────────────────

class _CapsuleSegmentSlider extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CapsuleSegmentSlider({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B162C) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
          width: 1.2,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              // Sliding Active Purple Capsule Pill Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5848D6),
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6942FF), Color(0xFF4930D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5848D6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // 3 Tab Buttons
              Row(
                children: [
                  _buildTabItem(0, 'Income', tabWidth, isDark),
                  _buildTabItem(1, 'Outflow', tabWidth, isDark),
                  _buildTabItem(2, 'Debt', tabWidth, isDark),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(int index, String label, double width, bool isDark) {
    final isSelected = selectedIndex == index;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF71819B)),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ─── Net Cash Flow Hero Card (Reference Matched) ─────────────────────────────

class _HeroFinancialCard extends StatelessWidget {
  final CashFlowPeriodModel period;
  const _HeroFinancialCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final net = period.netCashFlow;
    final isPositive = net >= 0;
    final formattedNet = '${isPositive ? '+' : ''}₹${NumberFormat('#,##0').format(net)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5848D6),
        gradient: const LinearGradient(
          colors: [Color(0xFF5848D6), Color(0xFF4930D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5848D6).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // Subtle Flowing Wave Texture Background
            Positioned.fill(
              child: CustomPaint(
                painter: _WaveBackgroundPainter(),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: NET CASH FLOW Label & Positive/Deficit Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NET CASH FLOW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPositive ? 'Positive' : 'Deficit',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Main Net Cash Flow Amount
                  Text(
                    formattedNet,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Inflow & Outflow Summary Row
                  Row(
                    children: [
                      // Inflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inflow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+₹${NumberFormat('#,##0').format(period.totalIncome)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Subtle Vertical Divider
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.25),
                      ),
                      const SizedBox(width: 16),
                      // Outflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outflow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '-₹${NumberFormat('#,##0').format(period.totalOutflow)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Bottom Sub-Account Balance Cards (Bank, Cash, Credit Card)
                  Row(
                    children: [
                      _buildAccountSubCard(
                        label: 'Bank',
                        value: period.closingBank,
                        icon: Icons.account_balance_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAccountSubCard(
                        label: 'Cash',
                        value: period.closingCash,
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAccountSubCard(
                        label: 'Credit Card',
                        value: period.closingCreditCard,
                        icon: Icons.credit_card_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSubCard({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '₹${NumberFormat('#,##0').format(value)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Subtle Flowing Wave Background Texture
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.cubicTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.65, size.height * 0.7,
      size.width, size.height * 0.3,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.35, size.height * 0.3,
      size.width * 0.75, size.height * 0.95,
      size.width, size.height * 0.55,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Month / Period Selector ──────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  final bool viewedPast;
  const _PeriodSelector({required this.viewedPast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode;
    final state = ref.watch(cashFlowProvider);
    final viewedId = ref.watch(_viewedPeriodIdProvider);
    final current = state.current.valueOrNull;
    final selected = viewedId == null || viewedId == current?.id
        ? current
        : state.history.where((p) => p.id == viewedId).firstOrNull;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _pickPeriod(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B162C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
            width: 1.2,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5848D6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: Color(0xFF5848D6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.label ?? 'August 2026',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected != null && !selected.isCurrent)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'READ ONLY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24,
              color: Color(0xFF71819B),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPeriod(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(cashFlowProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Consumer(builder: (context, ref, _) {
          final state = ref.watch(cashFlowProvider);
          final viewedId = ref.watch(_viewedPeriodIdProvider);
          final periods = [...state.history]
            ..sort((a, b) {
              if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
              final byDate = (b.year * 100 + b.month)
                  .compareTo(a.year * 100 + a.month);
              return byDate;
            });
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a month',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...periods.map((p) {
                  final isSelected = viewedId == null
                      ? p.isCurrent
                      : p.id == viewedId;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      p.isCurrent
                          ? Icons.radio_button_checked_rounded
                          : Icons.history_rounded,
                      size: 20,
                      color: p.isCurrent ? const Color(0xFF5848D6) : AppColors.textHint,
                    ),
                    title: Text(
                      p.isCurrent ? '${p.label}  ·  Current' : p.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isSelected
                            ? const Color(0xFF5848D6)
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      '₹${NumberFormat.compact().format(p.netCashFlow)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.netCashFlow >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF0445F),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (p.isCurrent) {
                        ref.read(_viewedPeriodIdProvider.notifier).state = null;
                        notifier.backToCurrent();
                      } else {
                        ref.read(_viewedPeriodIdProvider.notifier).state = p.id;
                        notifier.selectPeriod(p);
                      }
                    },
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  final VoidCallback onBack;
  const _ReadOnlyBanner({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Past months are read-only',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onBack,
            child: const Text(
              'Back to current',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5848D6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF5848D6).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5848D6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_outlined, size: 20, color: Color(0xFF5848D6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finish setting up this month',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Enter your starting balances once.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => SetupSheet.show(context),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ─── Debt Ledger Summary Card (Reference Matched) ─────────────────────────────

class _DebtSummaryTile extends StatelessWidget {
  final double yetToReceive;
  final double yetToGive;

  const _DebtSummaryTile({
    required this.yetToReceive,
    required this.yetToGive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => DebtLedgerSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B162C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF5848D6).withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5848D6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 22,
                color: Color(0xFF5848D6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debt Ledger',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Receive ',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        '+₹${NumberFormat.compact().format(yetToReceive)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '   Give ',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        '−₹${NumberFormat.compact().format(yetToGive)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF0445F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Color(0xFF71819B),
            ),
          ],
        ),
      ),
    );
  }
}
