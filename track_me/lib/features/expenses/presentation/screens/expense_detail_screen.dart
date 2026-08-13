import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/expense_model.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final cat = expense.category;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: cat.color,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cat.color, cat.color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Hero(
                        tag: 'expense_icon_${expense.id}',
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(cat.emoji,
                                style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Hero(
                        tag: 'expense_amount_${expense.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            '₹${NumberFormat('#,##0').format(expense.amount)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                _DetailCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Title',
                  value: expense.title,
                  color: cat.color,
                ),
                const SizedBox(height: 12),

                // Category
                _DetailCard(
                  icon: cat.icon,
                  label: 'Category',
                  value: cat.label,
                  color: cat.color,
                ),
                const SizedBox(height: 12),

                // Date
                _DetailCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: DateFormat('EEEE, MMM d, yyyy').format(expense.date),
                  color: cat.color,
                ),
                const SizedBox(height: 12),

                // Time
                if (expense.time != null && expense.time!.isNotEmpty) ...[
                  _DetailCard(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: expense.time!,
                    color: cat.color,
                  ),
                  const SizedBox(height: 12),
                ],

                // Payment Method
                _DetailCard(
                  icon: expense.paymentMethod.icon,
                  label: 'Payment Method',
                  value: expense.paymentMethod.label,
                  color: cat.color,
                ),
                const SizedBox(height: 12),

                // Notes
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  _DetailCard(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notes',
                    value: expense.notes!,
                    color: cat.color,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
