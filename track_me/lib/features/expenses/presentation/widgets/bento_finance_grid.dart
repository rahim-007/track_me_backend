import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class BentoFinanceGrid extends StatelessWidget {
  final double monthlyIncome;
  final double savingsTarget;
  final double spendableBudget;
  final double dailyGoal;
  final double todayTotal;
  final double savingsProgress;
  final double savingsRate;
  final double monthlyProfit;
  final double monthlyLoss;

  const BentoFinanceGrid({
    super.key,
    required this.monthlyIncome,
    required this.savingsTarget,
    required this.spendableBudget,
    required this.dailyGoal,
    required this.todayTotal,
    required this.savingsProgress,
    required this.savingsRate,
    required this.monthlyProfit,
    required this.monthlyLoss,
  });

  @override
  Widget build(BuildContext context) {
    final double profitVal = monthlyProfit;
    final double lossVal = monthlyLoss;

    return Column(
      children: [
        // Row 1: Income & Spendable Budget
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF8B5CF6), // Purple
                  value: '₹${NumberFormat('#,##0').format(monthlyIncome)}',
                  label: 'Monthly Income',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.trending_up_outlined,
                  iconColor: const Color(0xFFF97316), // Orange
                  value: '₹${NumberFormat('#,##0').format(spendableBudget)}',
                  label: 'Spendable',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Savings Progress & Target
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _BentoCard(
                height: 125,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BentoIconContainer(
                            icon: Icons.savings_outlined,
                            color: const Color(0xFF10B981), // Green
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Savings Rate',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(savingsRate * 100).clamp(0, 100).round()}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Goal ${(savingsProgress * 100).clamp(0, 100).round()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: savingsRate.clamp(0.0, 1.0),
                            strokeWidth: 4.5,
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            strokeCap: StrokeCap.round,
                          ),
                          const Center(
                            child: Icon(
                              Icons.star_rounded,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.track_changes_outlined,
                  iconColor: const Color(0xFF6366F1), // Indigo
                  value: '₹${NumberFormat('#,##0').format(savingsTarget)}',
                  label: 'Savings Target',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 3: Profit, Daily Limit, Loss
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981), // Green
                  value: '₹${NumberFormat('#,##0').format(profitVal)}',
                  label: 'Budget Left',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.calendar_today_outlined, // Calendar Icon
                  iconColor: const Color(0xFF3B82F6), // Blue
                  value: '₹${NumberFormat('#,##0').format(dailyGoal)}',
                  label: 'Daily Limit',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BentoCard(
                height: 125,
                child: _BentoTileContent(
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFEF4444), // Red
                  value: '₹${NumberFormat('#,##0').format(lossVal)}',
                  label: 'Over',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const _BentoCard({
    required this.child,
    this.height,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.isDarkMode 
                ? const Color(0xFF2D2A3A) 
                : const Color(0xFFE5E7EB), // Slate 200 border matching palette
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(AppColors.isDarkMode ? 0.15 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BentoIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BentoIconContainer({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _BentoTileContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _BentoTileContent({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BentoIconContainer(icon: icon, color: iconColor),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
