import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/cashflow_provider.dart';
import '../../data/models/cashflow_models.dart';

/// Bottom sheet for adding an entry: Inflow / Outflow / Debt.
///
/// Category model per spec:
///  - Income: E Employee, S Self-Employed, B Business, I Investor, G Gift
///  - Outflow: E Expense, S Savings, D Debt Repayment, I Investing, DO Donation
///  - Debt: direction (I owe / they owe me) + person + amount
///
/// Account selection:
///  - Inflow  → "Deposit to"  [Bank | Cash]          (default: Bank)
///  - Outflow → "Pay from"    [Bank | Cash | Credit Card] (default: Bank)
///  - Debt    → no account selector (existing debt ledger behaviour unchanged)
class AddEntrySheet extends ConsumerStatefulWidget {
  final int initialKindIndex;

  const AddEntrySheet({
    super.key,
    this.initialKindIndex = 0,
  });

  /// Returns true if something was added.
  static Future<bool> show(BuildContext context, {int initialKindIndex = 0}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEntrySheet(initialKindIndex: initialKindIndex),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  late int _kindIndex; // 0 income, 1 outflow, 2 debt

  @override
  void initState() {
    super.initState();
    _kindIndex = widget.initialKindIndex;
  }
  String? _category;
  bool _theyOweMe = true;
  CashFlowAccount _account = CashFlowAccount.bank;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isDebt => _kindIndex == 2;
  bool get _isInflow => _kindIndex == 0;

  /// Allowed accounts for the currently selected entry type.
  List<CashFlowAccount> get _accountOptions {
    if (_isInflow) {
      return [CashFlowAccount.bank, CashFlowAccount.cash];
    }
    // Outflow
    return [CashFlowAccount.bank, CashFlowAccount.cash, CashFlowAccount.creditCard];
  }

  List<(String, String, String)> get _categories {
    if (_kindIndex == 0) {
      return IncomeCategory.values
          .map((c) => (c.letter, c.label, c.description))
          .toList();
    }
    return OutflowCategory.values
        .map((c) => (c.letter, c.label, c.description))
        .toList();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _personCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    if (_isDebt && _personCtrl.text.trim().isEmpty) return;
    if (!_isDebt && _category == null) return;

    setState(() => _saving = true);
    final notifier = ref.read(cashFlowProvider.notifier);
    try {
      if (_isDebt) {
        await notifier.addDebt(DebtEntryModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          theyOweMe: _theyOweMe,
          person: _personCtrl.text.trim(),
          amount: amount,
          note: _noteCtrl.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(_date),
          settled: false,
        ));
      } else {
        await notifier.addTransaction(TransactionModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          kind: _kindIndex == 0 ? TxnKind.income : TxnKind.outflow,
          category: _category!,
          amount: amount,
          note: _noteCtrl.text.trim(),
          date: DateFormat('yyyy-MM-dd').format(_date),
          account: _account,
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save right now — kept offline'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                'Add Entry',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Inflow'), icon: Icon(Icons.south_west_rounded)),
                  ButtonSegment(value: 1, label: Text('Outflow'), icon: Icon(Icons.north_east_rounded)),
                  ButtonSegment(value: 2, label: Text('Debt'), icon: Icon(Icons.handshake_outlined)),
                ],
                selected: {_kindIndex},
                onSelectionChanged: (s) => setState(() {
                  _kindIndex = s.first;
                  _category = null;
                  // Reset account to Bank when switching type.
                  _account = CashFlowAccount.bank;
                }),
              ),
              const SizedBox(height: 20),
              if (_isDebt) ...[
                _DirectionToggle(
                  theyOweMe: _theyOweMe,
                  onChanged: (v) => setState(() => _theyOweMe = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _personCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Person',
                    hintText: 'Who is involved?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ] else ...[
                // ── Account selector (Deposit to / Pay from) ─────────────────
                _AccountSelector(
                  label: _isInflow ? 'Deposit to' : 'Pay from',
                  selected: _account,
                  options: _accountOptions,
                  onChanged: (a) => setState(() => _account = a),
                ),
                const SizedBox(height: 16),
                // ── Category list ─────────────────────────────────────────────
                ..._categories.map((c) {
                  final selected = _category == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _category = c.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  c.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.$2,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      c.$3,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(DateFormat('d MMM yyyy').format(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account selector — "Deposit to" or "Pay from"
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSelector extends StatelessWidget {
  final String label;
  final CashFlowAccount selected;
  final List<CashFlowAccount> options;
  final ValueChanged<CashFlowAccount> onChanged;

  const _AccountSelector({
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((acct) {
            final isSelected = selected == acct;
            final color = _accountColor(acct);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: acct != options.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onChanged(acct),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _accountEmoji(acct),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _accountShortLabel(acct),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _accountColor(CashFlowAccount acct) {
    switch (acct) {
      case CashFlowAccount.bank:
        return AppColors.primary;
      case CashFlowAccount.cash:
        return AppColors.success;
      case CashFlowAccount.creditCard:
        return AppColors.error;
    }
  }

  String _accountEmoji(CashFlowAccount acct) {
    switch (acct) {
      case CashFlowAccount.bank:
        return '🏦';
      case CashFlowAccount.cash:
        return '💵';
      case CashFlowAccount.creditCard:
        return '💳';
    }
  }

  String _accountShortLabel(CashFlowAccount acct) {
    switch (acct) {
      case CashFlowAccount.bank:
        return 'Bank';
      case CashFlowAccount.cash:
        return 'Cash';
      case CashFlowAccount.creditCard:
        return 'Credit Card';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debt direction toggle (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _DirectionToggle extends StatelessWidget {
  final bool theyOweMe;
  final ValueChanged<bool> onChanged;

  const _DirectionToggle({required this.theyOweMe, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DirectionCard(
            title: 'They owe me',
            subtitle: 'Yet to receive',
            icon: Icons.call_received_rounded,
            selected: theyOweMe,
            color: AppColors.success,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DirectionCard(
            title: 'I owe them',
            subtitle: 'Yet to give',
            icon: Icons.call_made_rounded,
            selected: !theyOweMe,
            color: AppColors.error,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.08) : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? color : AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
