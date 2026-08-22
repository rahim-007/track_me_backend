import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debt_model.dart';

/// Bottom sheet for creating or editing a debt. Pass [debt] to edit — all
/// fields are pre-filled and the save button label changes.
class AddEditDebtSheet extends StatefulWidget {
  final DebtModel? debt;
  final Future<bool> Function({
    required String name,
    required double originalAmount,
    String? lenderName,
    DateTime? dueDate,
    double? installmentAmount,
    String? description,
  }) onSave;

  const AddEditDebtSheet({super.key, this.debt, required this.onSave});

  @override
  State<AddEditDebtSheet> createState() => _AddEditDebtSheetState();
}

class _AddEditDebtSheetState extends State<AddEditDebtSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _lenderController;
  late final TextEditingController _installmentController;
  late final TextEditingController _descriptionController;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _nameController = TextEditingController(text: debt?.name ?? '');
    _amountController = TextEditingController(
      text: debt != null ? _fmt(debt.originalAmount) : '',
    );
    _lenderController = TextEditingController(text: debt?.lenderName ?? '');
    _installmentController = TextEditingController(
      text: debt?.installmentAmount != null
          ? _fmt(debt!.installmentAmount!)
          : '',
    );
    _descriptionController = TextEditingController(text: debt?.description ?? '');
    _dueDate = debt?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _lenderController.dispose();
    _installmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final originalAmount = _parseAmount(_amountController.text);
    final installment = _parseAmount(_installmentController.text);

    if (name.isEmpty) {
      _snack('Please enter a loan / debt name');
      return;
    }
    if (originalAmount == null || originalAmount <= 0) {
      _snack('Please enter an amount greater than 0');
      return;
    }
    if (installment != null && installment <= 0) {
      _snack('Installment amount must be greater than 0');
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(
      name: name,
      originalAmount: originalAmount,
      lenderName: _lenderController.text.trim().isEmpty
          ? null
          : _lenderController.text.trim(),
      dueDate: _dueDate,
      installmentAmount: installment,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _snack('Couldn\'t save. Check your connection and try again.');
      return;
    }
    Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
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
              _isEdit ? 'Edit Debt' : 'Add Debt / Loan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isEdit
                  ? 'Update the details below.'
                  : 'Track loans, EMIs and personal debts separately.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameController,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Loan / Debt Name',
                hint: 'e.g. Personal Loan',
                icon: Icons.account_balance_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Original amount
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                  labelText: 'Original Amount',
                  labelStyle:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lender
            TextField(
              controller: _lenderController,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Lender / Person (optional)',
                hint: 'e.g. Bank, Friend',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Due date
            GestureDetector(
              onTap: _pickDueDate,
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
                      _dueDate == null
                          ? 'Due date (optional)'
                          : DateFormat('EEEE, MMM d, yyyy').format(_dueDate!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dueDate == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Installment
            TextField(
              controller: _installmentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              ],
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Installment Amount (optional)',
                hint: 'e.g. 5000',
                icon: Icons.calendar_month_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Description (optional)',
                hint: 'Any notes about this loan',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving
                      ? 'Saving…'
                      : (_isEdit ? 'Save Changes' : 'Save Debt'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textHint),
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
