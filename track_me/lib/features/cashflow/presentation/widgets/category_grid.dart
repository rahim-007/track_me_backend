import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cashflow_models.dart';

/// ESBI grid (income) and ESDI grid (outflow): one tile per category with the
/// period's total and entry count. Pure display — all math comes from the
/// provider/server.
class CategoryGrid extends StatelessWidget {
  final bool income;
  final Map<String, double> totals;

  const CategoryGrid({
    super.key,
    required this.income,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = income
        ? IncomeCategory.values.map(_tileData).toList()
        : OutflowCategory.values.map(_tileData).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.05,
          children: tiles,
        ),
      ],
    );
  }

  Widget _tileData(dynamic c) {
    final total = totals[c.letter] ?? 0;
    return _CategoryTile(
      letter: c.letter,
      label: c.label,
      description: c.description,
      total: total,
      color: income ? const Color(0xFF10B981) : const Color(0xFFF0445F),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String letter;
  final String label;
  final String description;
  final double total;
  final Color color;

  const _CategoryTile({
    required this.letter,
    required this.label,
    required this.description,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B162C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF5B35F5).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${NumberFormat.compact().format(total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
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
