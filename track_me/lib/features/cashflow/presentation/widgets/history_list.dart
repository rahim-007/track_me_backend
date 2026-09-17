import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../providers/cashflow_provider.dart';
import '../../data/models/cashflow_models.dart';
import 'add_entry_sheet.dart';

enum TxnFilter {
  all('All'),
  inflow('📈 Income'),
  outflow('📉 Outflow'),
  bank('🏦 Bank'),
  cash('💵 Cash'),
  card('💳 Card');

  final String label;
  const TxnFilter(this.label);
}

final _txnFilterProvider = StateProvider<TxnFilter>((_) => TxnFilter.all);

/// Chronological list of every transaction in the selected period, with
/// filter pills and delete. Read-only when viewing a past month.
class HistoryList extends ConsumerWidget {
  final bool readOnly;
  final ScrollController? scrollController;

  const HistoryList({super.key, this.readOnly = false, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode;
    final txns = ref.watch(cashFlowProvider).transactions;
    final selectedFilter = ref.watch(_txnFilterProvider);

    if (txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
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
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF5848D6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 26,
                  color: Color(0xFF5848D6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No entries in this period yet.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add your first income or outflow.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Apply active filter
    final filtered = txns.where((t) {
      switch (selectedFilter) {
        case TxnFilter.all:
          return true;
        case TxnFilter.inflow:
          return t.kind == TxnKind.income;
        case TxnFilter.outflow:
          return t.kind == TxnKind.outflow;
        case TxnFilter.bank:
          return t.account == CashFlowAccount.bank;
        case TxnFilter.cash:
          return t.account == CashFlowAccount.cash;
        case TxnFilter.card:
          return t.account == CashFlowAccount.creditCard;
      }
    }).toList();

    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Filter Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: TxnFilter.values.map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: GestureDetector(
                  onTap: () => ref.read(_txnFilterProvider.notifier).state = filter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5848D6)
                          : (isDark ? const Color(0xFF1B162C) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5848D6)
                            : (isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5)),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF5848D6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : AppShadows.soft,
                    ),
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white.withOpacity(0.8) : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No transactions match "${selectedFilter.label}".',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...sorted.map((t) => _TxnTile(txn: t, readOnly: readOnly)),
      ],
    );
  }
}

class _TxnTile extends ConsumerWidget {
  final TransactionModel txn;
  final bool readOnly;

  const _TxnTile({required this.txn, required this.readOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode;
    final isIncome = txn.kind == TxnKind.income;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFF0445F);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B162C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: readOnly ? null : () => _openEdit(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    txn.category,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.note.isEmpty ? (isIncome ? 'Income' : 'Outflow') : txn.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('d MMM').format(DateTime.parse(txn.date))} · ${_accountBadge(txn.account)} · ${_categoryLabel(txn.category)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '−'}₹${NumberFormat('#,##0.##').format(txn.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: color,
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit transaction',
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textHint),
                    onPressed: () => _openEdit(context),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete transaction',
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 19, color: AppColors.textHint),
                    onPressed: () => _confirmDelete(context, ref, txn),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    AddEntrySheet.show(context, initialTransaction: txn);
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel txn,
  ) {
    final isIncome = txn.kind == TxnKind.income;
    final titleText =
        txn.note.isEmpty ? (isIncome ? 'Income' : 'Outflow') : txn.note;
    final amountFormatted =
        '${isIncome ? '+' : '−'}₹${NumberFormat('#,##0.##').format(txn.amount)}';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Transaction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this transaction ($titleText, $amountFormatted)? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(cashFlowProvider.notifier).deleteTransaction(txn.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String letter) {
    for (final c in IncomeCategory.values) {
      if (c.letter == letter) return c.label;
    }
    for (final c in OutflowCategory.values) {
      if (c.letter == letter) return c.label;
    }
    return letter;
  }

  String _accountBadge(CashFlowAccount account) {
    switch (account) {
      case CashFlowAccount.bank:
        return '🏦 Bank';
      case CashFlowAccount.cash:
        return '💵 Cash';
      case CashFlowAccount.creditCard:
        return '💳 Card';
    }
  }
}
