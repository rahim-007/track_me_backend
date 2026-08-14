import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/extra_income_model.dart';
import '../../providers/extra_income_provider.dart';

/// Standalone Extra Income page — a simple financial log that is fully
/// independent of the expense budget, income, savings and P&L calculations.
class ExtraIncomeScreen extends ConsumerStatefulWidget {
  const ExtraIncomeScreen({super.key});

  @override
  ConsumerState<ExtraIncomeScreen> createState() => _ExtraIncomeScreenState();
}

class _ExtraIncomeScreenState extends ConsumerState<ExtraIncomeScreen> {
  bool _addedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(extraIncomeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Extra Income',
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
          data: (entries) => entries.isEmpty && !_addedThisSession
              ? const EmptyStateWidget(
                  icon: Icons.payments_outlined,
                  title: 'No extra income yet',
                  subtitle: 'Add freelance work, cashback or any side income',
                )
              : _ExtraIncomeList(
                  entries: entries,
                  onDelete: _confirmDelete,
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
      builder: (_) => _AddExtraIncomeSheet(
        onSave: (title, amount, date) async {
          setState(() => _addedThisSession = true);
          await ref.read(extraIncomeProvider.notifier).add(
                title: title,
                amount: amount,
                date: date,
              );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ExtraIncomeModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          '"${entry.title}" of ₹${NumberFormat('#,##0').format(entry.amount)} will be removed.',
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
      await ref.read(extraIncomeProvider.notifier).remove(entry.id);
    }
  }
}

// ─── Entry List with fade-in animation ──────────────────────────────────────

class _ExtraIncomeList extends StatelessWidget {
  final List<ExtraIncomeModel> entries;
  final void Function(ExtraIncomeModel entry) onDelete;

  const _ExtraIncomeList({required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0.0, (sum, e) => sum + e.amount);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => () {}, // pull-to-refresh handled by provider load
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Total banner
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
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
                    child: const Icon(Icons.savings_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EXTRA INCOME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##0').format(total)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...entries.asMap().entries.map((item) {
            final index = item.key;
            final entry = item.value;
            return TweenAnimationBuilder<double>(
              key: ValueKey(entry.id),
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
                child: _ExtraIncomeCard(entry: entry, onDelete: onDelete),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Entry Card ───────────────────────────────────────────────

class _ExtraIncomeCard extends StatefulWidget {
  final ExtraIncomeModel entry;
  final void Function(ExtraIncomeModel entry) onDelete;

  const _ExtraIncomeCard({required this.entry, required this.onDelete});

  @override
  State<_ExtraIncomeCard> createState() => _ExtraIncomeCardState();
}

class _ExtraIncomeCardState extends State<_ExtraIncomeCard> {
  bool _removing = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _removing ? 0 : 1,
      child: GestureDetector(
        onTap: () => setState(() {}),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _removing ? 0.95 : 1.0,
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
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.attach_money_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('d MMM yyyy').format(entry.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+ ₹${NumberFormat('#,##0').format(entry.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    setState(() => _removing = true);
                    Future.delayed(const Duration(milliseconds: 220), () {
                      widget.onDelete(entry);
                    });
                  },
                  icon: Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add Extra Income Sheet ─────────────────────────────────────────────────

class _AddExtraIncomeSheet extends StatefulWidget {
  final void Function(String title, double amount, DateTime date) onSave;

  const _AddExtraIncomeSheet({required this.onSave});

  @override
  State<_AddExtraIncomeSheet> createState() => _AddExtraIncomeSheetState();
}

class _AddExtraIncomeSheetState extends State<_AddExtraIncomeSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an income name')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }
    widget.onSave(title, amount, _selectedDate);
    Navigator.pop(context);
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
              'Add Extra Income',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Freelance, cashback, gifts — tracked separately from your budget.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Income Name
            TextField(
              controller: _titleController,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Income Name',
                hintText: 'e.g. Freelance Work',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textHint),
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
            const SizedBox(height: 16),

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
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date
            Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
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
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
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
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Income',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
