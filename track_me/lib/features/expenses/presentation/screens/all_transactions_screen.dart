import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/expense_analytics_provider.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/transaction_card.dart';

/// Dedicated "All Transactions" screen.
///
/// Shows every transaction stored for the user, newest first, using the same
/// source of truth as the Expenses dashboard (`expensesListProvider` -> GET /expenses).
/// Adding or deleting a transaction here immediately updates this list, the
/// dashboard's Recent Transactions, the category/daily/monthly charts and Analytics.
class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(expensesListProvider.notifier).loadExpenses();
    });
  }

  void _showAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        onSave: (expense) async {
          await ref.read(expensesListProvider.notifier).addExpense(expense);
          ref.read(expenseDashboardProvider.notifier).reload();
          ref.read(expenseAnalyticsProvider.notifier).reload();
        },
      ),
    );
  }

  Future<void> _deleteExpense(String id) async {
    await ref.read(expensesListProvider.notifier).deleteExpense(id);
    ref.read(expenseDashboardProvider.notifier).reload();
    ref.read(expenseAnalyticsProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(expensesListProvider);
    final hasTransactions = transactionsState.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      // In the empty state the "Add Transaction" button is shown instead.
      floatingActionButton: hasTransactions
          ? FloatingActionButton(
              onPressed: _showAddExpense,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'All Transactions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: transactionsState.when(
        skipLoadingOnRefresh: true,
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('Error loading transactions')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'No transactions yet',
              subtitle: 'Add your first transaction to start tracking your spending.',
              actionLabel: 'Add Transaction',
              onAction: _showAddExpense,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary line
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  transactions.length == 1
                      ? '1 transaction'
                      : '${transactions.length} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(expensesListProvider.notifier).loadExpenses(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final exp = transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionCard(
                          expense: exp,
                          onTap: () =>
                              context.push(AppRoutes.expenseDetail, extra: exp),
                          onDelete: () => _deleteExpense(exp.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
