import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/expense_category.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = expense.category;
    final timeStr = expense.time ?? '';
    final dateStr = DateFormat('MMM d').format(expense.date);
    final isToday = DateFormat('yyyy-MM-dd').format(expense.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Hero(
              tag: 'expense_icon_${expense.id}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.isDarkMode ? cat.color.withOpacity(0.15) : cat.lightColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isToday ? 'Today' : dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      Text(
                        ' • ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Text(
                        expense.paymentMethod.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cat.color,
                        ),
                      ),
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.sticky_note_2_outlined,
                            size: 13, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Builder(builder: (context) {
              final isIncome = expense.category == ExpenseCategory.salary;
              final prefix = isIncome ? '+ ' : '- ';
              final amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
              return Hero(
                tag: 'expense_amount_${expense.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    '$prefix₹${NumberFormat('#,##0').format(expense.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                ),
              );
            }),
            // More menu
            if (onDelete != null)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
