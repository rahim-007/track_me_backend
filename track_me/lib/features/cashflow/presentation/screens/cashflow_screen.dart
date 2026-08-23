import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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

/// Cash Flow dashboard.
///
/// Layout per spec: period selector, four balance cards, inflow vs outflow
/// summary with net cash flow, ESBI grid, ESDI grid, debt summary tile and
/// the period's transaction history. Past months are read-only.
class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 24),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(cashFlowProvider.notifier).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
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
              const SizedBox(height: 4),
              Text(
                'Where your money comes from and where it goes',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 12),
        _BalanceCards(period: period),
        const SizedBox(height: 12),
        _InflowVsOutflowCard(period: period),
        const SizedBox(height: 20),
        const _SectionTitle('WHERE MONEY COMES FROM'),
        const SizedBox(height: 8),
        CategoryGrid(income: true, totals: period.incomeByCategory),
        const SizedBox(height: 20),
        const _SectionTitle('WHERE MONEY GOES'),
        const SizedBox(height: 8),
        CategoryGrid(income: false, totals: period.outflowByCategory),
        const SizedBox(height: 20),
        _DebtSummaryTile(
          yetToReceive: state.yetToReceive,
          yetToGive: state.yetToGive,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('THIS PERIOD'),
        const SizedBox(height: 8),
        HistoryList(readOnly: viewedPast),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Period selector
// ---------------------------------------------------------------------------

class _PeriodSelector extends ConsumerWidget {
  final bool viewedPast;
  const _PeriodSelector({required this.viewedPast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashFlowProvider);
    final viewedId = ref.watch(_viewedPeriodIdProvider);
    final current = state.current.valueOrNull;
    final selected = viewedId == null || viewedId == current?.id
        ? current
        : state.history.where((p) => p.id == viewedId).firstOrNull;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickPeriod(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected?.label ?? 'Select month',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected != null && !selected.isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('READ ONLY',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary)),
              ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, size: 20,
                color: AppColors.textSecondary),
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
          // Newest first; current pinned on top.
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
                Text('Choose a month',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...periods.map((p) {
                  final isSelected = viewedId == null
                      ? p.isCurrent
                      : p.id == viewedId;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      p.isCurrent
                          ? Icons.radio_button_checked_rounded
                          : Icons.history_rounded,
                      size: 20,
                      color:
                          p.isCurrent ? AppColors.primary : AppColors.textHint,
                    ),
                    title: Text(
                      p.isCurrent ? '${p.label}  ·  Current' : p.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      '₹${NumberFormat.compact().format(p.netCashFlow)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.netCashFlow >= 0
                            ? AppColors.success
                            : AppColors.error,
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
            child: Text(
              'Back to current',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown once when the freshly-opened period still has all-zero balances.
class _SetupPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.rocket_launch_outlined, size: 20, color: AppColors.primary),
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
                      color: AppColors.textPrimary),
                ),
                Text(
                  'Enter your starting balances once.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
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

// ---------------------------------------------------------------------------
// Balance cards
// ---------------------------------------------------------------------------

class _BalanceCards extends StatelessWidget {
  final CashFlowPeriodModel period;
  const _BalanceCards({required this.period});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _BalanceCard(
          label: 'Bank',
          value: period.closingBank,
          icon: Icons.account_balance_rounded,
          accent: AppColors.primary,
          sub: 'Updates with every entry',
        ),
        _BalanceCard(
          label: 'Cash in hand',
          value: period.closingCash,
          icon: Icons.payments_rounded,
          accent: AppColors.success,
          sub: 'Updates with every entry',
        ),
        _BalanceCard(
          label: 'Credit card',
          value: period.closingCreditCard,
          icon: Icons.credit_card_rounded,
          accent: AppColors.error,
          sub: 'Owed this month',
        ),
        _BalanceCard(
          label: 'Net this month',
          value: period.netCashFlow,
          icon: Icons.trending_up_rounded,
          accent: period.netCashFlow >= 0
              ? AppColors.success
              : AppColors.error,
          sub: 'Inflow − outflow',
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color accent;
  final String sub;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '₹${NumberFormat('#,##0.##').format(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inflow vs outflow
// ---------------------------------------------------------------------------

class _InflowVsOutflowCard extends StatelessWidget {
  final CashFlowPeriodModel period;
  const _InflowVsOutflowCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final total = period.totalIncome + period.totalOutflow;
    final incomeShare = total == 0 ? 0.5 : period.totalIncome / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.south_west_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text('Inflow',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      '+₹${NumberFormat('#,##0.##').format(period.totalIncome)}',
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.success),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Outflow',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 5),
                        Icon(Icons.north_east_rounded,
                            size: 16, color: AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '−₹${NumberFormat('#,##0.##').format(period.totalOutflow)}',
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: (incomeShare * 1000).round().clamp(1, 999),
                      child: ColoredBox(color: AppColors.success)),
                  Expanded(flex: ((1 - incomeShare) * 1000).round().clamp(1, 999),
                      child: ColoredBox(color: AppColors.error)),
                ],
              ),
            ),
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

// ---------------------------------------------------------------------------
// Debt summary tile
// ---------------------------------------------------------------------------

class _DebtSummaryTile extends StatelessWidget {
  final double yetToReceive;
  final double yetToGive;

  const _DebtSummaryTile({
    required this.yetToReceive,
    required this.yetToGive,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => DebtLedgerSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.handshake_outlined,
                  size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debt Ledger',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('Receive ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text('+₹${NumberFormat.compact().format(yetToReceive)}',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success)),
                      Text('   Give ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text('−₹${NumberFormat.compact().format(yetToGive)}',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
