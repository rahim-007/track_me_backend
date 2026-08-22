import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/debt_model.dart';
import '../../providers/debts_provider.dart';
import '../widgets/add_edit_debt_sheet.dart';

/// Debt / Loan tracker home — standalone from Cash Flow.
class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Debt / Loan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        child: state.when(
          skipLoadingOnRefresh: true,
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => const Center(child: Text('Something went wrong')),
          data: (debts) => debts.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.account_balance_outlined,
                  title: 'No debts yet',
                  subtitle: 'Add a loan or personal debt to start tracking payments',
                )
              : _DebtList(
                  debts: debts,
                  onTap: (debt) => context.push(AppRoutes.debtDetail, extra: debt),
                ),
        ),
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditDebtSheet(
        onSave: ({
          required name,
          required originalAmount,
          lenderName,
          dueDate,
          installmentAmount,
          description,
        }) async {
          return ref.read(debtsProvider.notifier).add(
                name: name,
                originalAmount: originalAmount,
                lenderName: lenderName,
                dueDate: dueDate,
                installmentAmount: installmentAmount,
                description: description,
              );
        },
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<DebtModel> debts;
  final void Function(DebtModel debt) onTap;

  const _DebtList({required this.debts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = debts.where((d) => !d.isPaid).toList();
    final paid = debts.length - active.length;
    final outstanding =
        active.fold<double>(0.0, (sum, d) => sum + d.remainingBalance);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => () {}, // pull-to-refresh handled by provider load
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Summary banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL OUTSTANDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##0').format(outstanding)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$active active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$paid paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...debts.asMap().entries.map((item) {
            final index = item.key;
            final debt = item.value;
            return TweenAnimationBuilder<double>(
              key: ValueKey(debt.id),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + index * 60),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DebtCard(debt: debt, onTap: () => onTap(debt)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;

  const _DebtCard({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.04),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (debt.lenderName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          debt.lenderName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusChip(isPaid: debt.isPaid),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            // Original / Paid / Remaining
            Row(
              children: [
                _Stat(label: 'Original', value: debt.originalAmount),
                _Stat(label: 'Paid', value: debt.totalPaid),
                _Stat(label: 'Remaining', value: debt.remainingBalance, highlight: true),
              ],
            ),
            const SizedBox(height: 12),
            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  debt.isPaid ? AppColors.primary : const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isPaid;

  const _StatusChip({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.primary : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Active',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const _Stat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${NumberFormat('#,##0').format(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
