import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/expenses_provider.dart';

class ExpenseSetupWizard extends ConsumerStatefulWidget {
  const ExpenseSetupWizard({super.key});

  @override
  ConsumerState<ExpenseSetupWizard> createState() => _ExpenseSetupWizardState();
}

class _ExpenseSetupWizardState extends ConsumerState<ExpenseSetupWizard> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  /// True while a page transition is running — guards against double-taps on
  /// Continue advancing two pages at once.
  bool _isAnimatingPage = false;

  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  final _incomeFocusNode = FocusNode();
  final _savingsFocusNode = FocusNode();

  /// Set once the user edits a field, so the async budget pre-fill never
  /// overwrites (or resurrects) a value the user has already typed or cleared.
  bool _userEditedIncome = false;
  bool _userEditedSavings = false;

  late int _selectedMonth;
  late int _selectedYear;
  late int _daysInMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

    _incomeController.addListener(_onIncomeChanged);
    _savingsController.addListener(_onSavingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetState = ref.read(budgetProvider);
      budgetState.whenData((budget) {
        if (budget != null && mounted) {
          setState(() {
            // Pre-fill only fields the user hasn't touched. This keeps the
            // entered value intact when the budget resolves after the user
            // has already started (or finished) typing.
            if (!_userEditedIncome && _incomeController.text.isEmpty) {
              _incomeController.text = budget.monthlyIncome % 1 == 0
                  ? budget.monthlyIncome.toInt().toString()
                  : budget.monthlyIncome.toString();
            }
            if (!_userEditedSavings && _savingsController.text.isEmpty) {
              _savingsController.text = budget.savingsTarget % 1 == 0
                  ? budget.savingsTarget.toInt().toString()
                  : budget.savingsTarget.toString();
            }
            _selectedMonth = budget.month;
            _selectedYear = budget.year;
            _daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
          });
        }
      });
    });
  }

  void _onIncomeChanged() {
    _userEditedIncome = true;
    setState(() {});
  }

  void _onSavingsChanged() {
    _userEditedSavings = true;
    setState(() {});
  }

  /// Days the budget actually covers: for the current month, from today (the
  /// day the budget starts) to month end; for other months, the full month.
  int get _budgetDays {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      final remaining = _daysInMonth - now.day + 1;
      return remaining.clamp(1, _daysInMonth);
    }
    return _daysInMonth;
  }

  @override
  void dispose() {
    _incomeController.removeListener(_onIncomeChanged);
    _savingsController.removeListener(_onSavingsChanged);
    _pageController.dispose();
    _incomeController.dispose();
    _savingsController.dispose();
    _incomeFocusNode.dispose();
    _savingsFocusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Never allow a second tap to advance while a transition is running.
    if (_isAnimatingPage || _currentPage >= 2) return;

    if (_currentPage == 0) {
      final income = double.tryParse(_incomeController.text.replaceAll(',', ''));
      if (income == null || income <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid income')),
        );
        return;
      }
    }
    if (_currentPage == 1) {
      final savings = double.tryParse(_savingsController.text.replaceAll(',', ''));
      final income = double.tryParse(_incomeController.text.replaceAll(',', ''));
      if (savings == null || savings < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid savings target')),
        );
        return;
      }
      if (income != null && savings >= income) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savings must be less than income')),
        );
        return;
      }
    }

    // Dismiss the keyboard first so the page slides without racing the
    // keyboard-driven viewport resize, then hand focus to the next field once
    // the transition has fully settled.
    setState(() => _isAnimatingPage = true);
    FocusManager.instance.primaryFocus?.unfocus();
    _pageController
        .nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
      if (!mounted) return;
      setState(() => _isAnimatingPage = false);
      // The incoming field should be focused/ready for input.
      if (_currentPage == 1) {
        _savingsFocusNode.requestFocus();
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final income = double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0;
    final savings = double.tryParse(_savingsController.text.replaceAll(',', '')) ?? 0;

    await ref.read(budgetProvider.notifier).saveBudget(
      monthlyIncome: income,
      savingsTarget: savings,
      month: _selectedMonth,
      year: _selectedYear,
    );

    // Reload dashboard data
    ref.read(expenseDashboardProvider.notifier).loadDashboard();

    if (mounted) {
      context.go(AppRoutes.expenses);
    }
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
                      ),
                    ),
                  const Spacer(),
                  // Step indicator
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i == _currentPage;
                      final isDone = i < _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(left: 6),
                        width: isActive ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive || isDone
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() {
                  _currentPage = i;
                }),
                children: [
                  _buildIncomePage(),
                  _buildSavingsPage(),
                  _buildMonthPage(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : (_currentPage < 2 ? _nextPage : _finish),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: AppColors.primary.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentPage < 2 ? 'Continue' : 'Get Started 🚀',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Monthly Income',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How much do you earn each month?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode ? AppColors.primary.withOpacity(0.12) : const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _incomeController,
              focusNode: _incomeFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              autofocus: true,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                hintText: '20,000',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏦',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Savings Target',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How much do you want to save?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _savingsController,
              focusNode: _savingsFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              // Focus is handed here explicitly after the page transition
              // settles (see _nextPage), which is more reliable than autofocus
              // firing mid PageView animation.
              autofocus: false,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
                hintText: '5,000',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Preview
          Builder(builder: (_) {
            final income = double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0.0;
            final savings = double.tryParse(_savingsController.text.replaceAll(',', '')) ?? 0.0;
            if (income <= 0) return const SizedBox.shrink();
            
            final spendable = income - savings;
            final dailyGoal = _budgetDays > 0 ? spendable / _budgetDays : 0.0;
            
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Calculation Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PreviewRow(label: 'Monthly Income', value: '₹${NumberFormat('#,##0').format(income)}'),
                  const SizedBox(height: 6),
                  _PreviewRow(label: 'Savings Target', value: '₹${NumberFormat('#,##0').format(savings)}', color: const Color(0xFF10B981)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  _PreviewRow(
                    label: 'Spendable Budget',
                    value: '₹${NumberFormat('#,##0').format(spendable)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _PreviewRow(
                    label: 'Daily Spendable Limit',
                    value: '₹${NumberFormat('#,##0').format(dailyGoal < 0 ? 0.0 : dailyGoal)}/day',
                    isBold: true,
                    color: AppColors.primary,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthPage() {
    final income = double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0;
    final savings = double.tryParse(_savingsController.text.replaceAll(',', '')) ?? 0;
    final spendable = income - savings;
    final dailyGoal = _budgetDays > 0 ? spendable / _budgetDays : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Month',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_monthNames[_selectedMonth - 1]} $_selectedYear • $_daysInMonth days',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            // Month selector
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final isSelected = m == _selectedMonth;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = m;
                        _daysInMonth = DateTime(_selectedYear, m + 1, 0).day;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        _monthNames[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Summary preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.isDarkMode
                      ? [AppColors.surfaceVariant, AppColors.surfaceVariant]
                      : [const Color(0xFFF3F0FF), const Color(0xFFEBE5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Budget Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Monthly Income', value: '₹${NumberFormat('#,##0').format(income)}'),
                  _SummaryRow(label: 'Savings Target', value: '₹${NumberFormat('#,##0').format(savings)}'),
                  Divider(height: 20, color: AppColors.primary),
                  _SummaryRow(
                    label: 'Spendable Budget',
                    value: '₹${NumberFormat('#,##0').format(spendable)}',
                    isBold: true,
                  ),
                  _SummaryRow(
                    label: 'Daily Goal',
                    value: '₹${NumberFormat('#,##0').format(dailyGoal)}/day',
                    isBold: true,
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
