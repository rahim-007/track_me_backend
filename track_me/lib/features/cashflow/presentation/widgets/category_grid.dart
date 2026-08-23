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
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 2.35,
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
      color: income ? AppColors.success : AppColors.error,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 11),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '₹${NumberFormat.compact().format(total)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: total > 0 ? color : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
