import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/debt_model.dart';
import '../../providers/debts_provider.dart';
import '../widgets/add_edit_debt_sheet.dart';
import '../widgets/record_payment_sheet.dart';

/// Debt detail — shows totals, progress, payment history and actions.
class DebtDetailScreen extends ConsumerWidget {
  final DebtModel initialDebt;

  const DebtDetailScreen({super.key, required this.initialDebt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live copy from the provider so payments/edits reflect immediately.
    final debt = ref
            .watch(debtsProvider)
            .valueOrNull
            ?.where((d) => d.id == initialDebt.id)
            .firstOrNull ??
        initialDebt;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Debt Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context, ref, debt),
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _HeaderCard(debt: debt),
            const SizedBox(height: 16),
            _SummaryCard(debt: debt),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditSheet(context, ref, debt),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          debt.isPaid ? null : () => _showPaymentSheet(context, ref, debt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        debt.isPaid ? 'Paid Off' : 'Record Payment',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (debt.payments.isEmpty)
              const EmptyStateWidget(
                icon: Icons.payments_outlined,
                title: 'No payments yet',
                subtitle: 'Record your first payment to start tracking progress',
              )
            else
              ...debt.payments.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PaymentCard(payment: p),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, DebtModel debt) {
    showModalBottomSheet<DebtModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentSheet(
        debt: debt,
        onSave: ({required amount, paymentDate, note}) async {
          return ref.read(debtsProvider.notifier).recordPayment(
                debt.id,
                amount: amount,
                paymentDate: paymentDate,
                note: note,
              );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditDebtSheet(
        debt: debt,
        onSave: ({
          required name,
          required originalAmount,
          lenderName,
          dueDate,
          installmentAmount,
          description,
        }) async {
          return ref.read(debtsProvider.notifier).update(
                debt.id,
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, DebtModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this debt?'),
        content: Text(
          '"${debt.name}" and its payment history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(debtsProvider.notifier).remove(debt.id);
      if (context.mounted) context.pop();
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final DebtModel debt;

  const _HeaderCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (debt.lenderName != null)
                      Text(
                        debt.lenderName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusChip(isPaid: debt.isPaid),
            ],
          ),
          if (debt.description != null) ...[
            const SizedBox(height: 14),
            Text(
              debt.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (debt.dueDate != null || debt.installmentAmount != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (debt.dueDate != null) ...[
                  Icon(Icons.event_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${DateFormat('d MMM yyyy').format(debt.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (debt.dueDate != null && debt.installmentAmount != null)
                  const SizedBox(width: 16),
                if (debt.installmentAmount != null) ...[
                  Icon(Icons.calendar_month_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '₹${NumberFormat('#,##0').format(debt.installmentAmount!)} / installment',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DebtModel debt;

  const _SummaryCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${NumberFormat('#,##0').format(debt.remainingBalance)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
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
                    'Paid ₹${NumberFormat('#,##0').format(debt.totalPaid)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of ₹${NumberFormat('#,##0').format(debt.originalAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: debt.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                debt.isPaid ? AppColors.primary : const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(debt.progress * 100).round()}% paid',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final DebtPaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(payment.paymentDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (payment.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    payment.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹${NumberFormat('#,##0').format(payment.amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
            ),
          ),
        ],
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
