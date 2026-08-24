import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cashflow_models.dart';
import '../../providers/cashflow_provider.dart';
import 'debt_detail_sheet.dart';

/// Two-column ledger: Yet to Receive / Yet to Give. Continuous — entries
/// persist across month boundaries until settled or deleted.
class DebtLedgerSheet extends ConsumerStatefulWidget {
  /// Controller from the surrounding [DraggableScrollableSheet] so dragging
  /// the list dismisses the sheet naturally.
  final ScrollController? scrollController;

  const DebtLedgerSheet({super.key, this.scrollController});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DebtLedgerSheet(scrollController: scrollController),
        ),
      ),
    );
  }

  @override
  ConsumerState<DebtLedgerSheet> createState() => _DebtLedgerSheetState();
}

class _DebtLedgerSheetState extends ConsumerState<DebtLedgerSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashFlowProvider);
    final receive =
        state.debts.where((d) => d.theyOweMe && !d.settled).toList();
    final give = state.debts.where((d) => !d.theyOweMe && !d.settled).toList();
    final settled = state.debts.where((d) => d.settled).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Debt Ledger',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Continuous — never resets at month end',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LedgerColumn(
                      title: 'Yet to Receive',
                      total: state.yetToReceive,
                      positive: true,
                      entries: receive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LedgerColumn(
                      title: 'Yet to Give',
                      total: state.yetToGive,
                      positive: false,
                      entries: give,
                    ),
                  ),
                ],
              ),
              if (settled.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Settlement History',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${settled.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...settled.map((d) => _DebtTile(entry: d, settledSection: true)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerColumn extends StatelessWidget {
  final String title;
  final double total;
  final bool positive;
  final List<DebtEntryModel> entries;

  const _LedgerColumn({
    required this.title,
    required this.total,
    required this.positive,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${NumberFormat('#,##0').format(total)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: positive ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'Nothing here',
              style: TextStyle(fontSize: 11.5, color: AppColors.textHint),
            )
          else
            ...entries.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _MiniEntry(entry: d),
                )),
        ],
      ),
    );
  }
}

class _MiniEntry extends StatelessWidget {
  final DebtEntryModel entry;
  const _MiniEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => DebtDetailSheet.show(context, entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.person,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '₹${NumberFormat.compact().format(entry.amount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: entry.theyOweMe ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  final DebtEntryModel entry;
  final bool settledSection;

  const _DebtTile({required this.entry, this.settledSection = false});

  String _formatSettledDate(String? settledAtIso) {
    if (settledAtIso == null || settledAtIso.isEmpty) {
      return DateFormat('d MMM yyyy').format(DateTime.parse(entry.date));
    }
    try {
      final dt = DateTime.parse(settledAtIso).toLocal();
      return DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(DateTime.parse(entry.date));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = entry.theyOweMe ? AppColors.success : AppColors.error;
    return InkWell(
      onTap: () => DebtDetailSheet.show(context, entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.person,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      decoration:
                          entry.settled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##0').format(entry.amount)}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: color),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onSelected: (action) async {
                    final notifier = ref.read(cashFlowProvider.notifier);
                    if (action == 'settle') {
                      await notifier.setDebtSettled(entry, !entry.settled);
                    } else if (action == 'delete') {
                      await notifier.deleteDebt(entry.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'settle',
                      child: Text(entry.settled ? 'Mark unsettled' : 'Mark settled'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  entry.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    entry.settled
                        ? (entry.theyOweMe
                            ? 'Received: ${_formatSettledDate(entry.settledAt)}'
                            : 'Settled: ${_formatSettledDate(entry.settledAt)}')
                        : DateFormat('d MMM yyyy').format(DateTime.parse(entry.date)),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: entry.settled ? FontWeight.w700 : FontWeight.normal,
                      color: entry.settled ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
