import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/cashflow_provider.dart';
import '../../data/models/cashflow_models.dart';

/// Chronological list of every transaction in the selected period, with
/// delete. Read-only when viewing a past month.
class HistoryList extends ConsumerWidget {
  final bool readOnly;
  final ScrollController? scrollController;

  const HistoryList({super.key, this.readOnly = false, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(cashFlowProvider).transactions;

    if (txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No entries in this period yet.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final sorted = [...txns]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sorted.map((t) => _TxnTile(txn: t, readOnly: readOnly)).toList(),
    );
  }
}

class _TxnTile extends ConsumerWidget {
  final TransactionModel txn;
  final bool readOnly;

  const _TxnTile({required this.txn, required this.readOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = txn.kind == TxnKind.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              txn.category,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
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
                  txn.note.isEmpty ? (isIncome ? 'Inflow' : 'Outflow') : txn.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${DateFormat('d MMM').format(DateTime.parse(txn.date))} · ${_categoryLabel(txn.category)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '−'}₹${NumberFormat('#,##0.##').format(txn.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: color,
            ),
          ),
          if (!readOnly)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 19, color: AppColors.textHint),
              onPressed: () =>
                  ref.read(cashFlowProvider.notifier).deleteTransaction(txn.id),
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
}
