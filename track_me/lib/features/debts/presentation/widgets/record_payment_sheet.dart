import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debt_model.dart';

/// Bottom sheet to record a payment against a debt. Shows the remaining
/// balance and rejects amounts that would overpay (the backend enforces this
/// too, but we catch it here for instant feedback).
class RecordPaymentSheet extends StatefulWidget {
  final DebtModel debt;
  final Future<DebtModel?> Function({
    required double amount,
    DateTime? paymentDate,
    String? note,
  }) onSave;

  const RecordPaymentSheet({super.key, required this.debt, required this.onSave});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) {
      _snack('Please enter an amount greater than 0');
      return;
    }
    final remaining = widget.debt.remainingBalance;
    if (amount > remaining + 0.001) {
      _snack('Amount exceeds remaining balance (₹${NumberFormat('#,##0').format(remaining)})');
      return;
    }

    setState(() => _saving = true);
    final updated = await widget.onSave(
      amount: amount,
      paymentDate: _paymentDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated == null) {
      _snack('Couldn\'t save the payment. Check your connection and try again.');
      return;
    }
    Navigator.pop(context, updated);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Text(
              'Record Payment',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              debt.name,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Remaining summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original: ₹${NumberFormat('#,##0').format(debt.originalAmount)}',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Already paid: ₹${NumberFormat('#,##0').format(debt.totalPaid)}',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remaining: ₹${NumberFormat('#,##0').format(debt.remainingBalance)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.isDarkMode
                    ? AppColors.primary.withOpacity(0.12)
                    : const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                ],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  labelText: 'Payment Amount',
                  labelStyle:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _paymentDate = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_paymentDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. EMI for August',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textHint),
                prefixIcon:
                    Icon(Icons.notes_rounded, size: 20, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.success.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving…' : 'Save Payment',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
