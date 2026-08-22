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
  final double extraIncomeTotal;
  final int extraIncomeCount;
  final VoidCallback? onExtraIncomeTap;
  final double debtTotal;
  final int debtCount;
  final VoidCallback? onDebtTap;

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
    this.extraIncomeTotal = 0,
    this.extraIncomeCount = 0,
    this.onExtraIncomeTap,
    this.debtTotal = 0,
    this.debtCount = 0,
    this.onDebtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Monthly Income, Spendable, Extra Income
        // IntrinsicHeight keeps every card in the row the same height while
        // allowing the row to grow when a card's content needs more room.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  child: _BentoTileContent(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    value: '₹${NumberFormat('#,##0').format(monthlyIncome)}',
                    label: 'Monthly Income',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  child: _BentoTileContent(
                    icon: Icons.trending_up_outlined,
                    iconColor: const Color(0xFFF97316),
                    value: '₹${NumberFormat('#,##0').format(spendableBudget)}',
                    label: 'Spendable',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExtraIncomeCard(
                  total: extraIncomeTotal,
                  count: extraIncomeCount,
                  onTap: onExtraIncomeTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 2: Savings Rate, Savings Target
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: _BentoCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _BentoIconContainer(
                              icon: Icons.savings_outlined,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Savings Rate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Large savings progress ring with star icon
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: savingsRate.clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor:
                                  const Color(0xFF10B981).withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981)),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _BentoIconContainer(
                        icon: Icons.track_changes_outlined,
                        color: Color(0xFF6366F1),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Target',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${NumberFormat('#,##0').format(savingsTarget)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 3: Loss, Daily Limit, Profit
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  child: _BentoTileContent(
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    value: '₹${NumberFormat('#,##0').format(monthlyLoss)}',
                    label: 'Loss',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  child: _BentoTileContent(
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    value: '₹${NumberFormat('#,##0').format(dailyGoal)}',
                    label: 'Daily Limit',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCard(
                  child: _BentoTileContent(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    value: '₹${NumberFormat('#,##0').format(monthlyProfit)}',
                    label: 'Profit',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 4: Debt / Loan Tracker entry (standalone — informational only)
        _DebtLoanCard(
          total: debtTotal,
          count: debtCount,
          onTap: onDebtTap,
        ),
      ],
    );
  }
}

/// Standalone Debt / Loan Tracker entry tile — thin purple outline.
/// Shows total outstanding (informational); never feeds Cash Flow calculations.
class _DebtLoanCard extends StatelessWidget {
  final double total;
  final int count;
  final VoidCallback? onTap;

  const _DebtLoanCard({
    required this.total,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: 1.0,
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(AppColors.isDarkMode ? 0.15 : 0.03),
                blurRadius: 16,
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
                child: Icon(Icons.account_balance_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt / Loan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹${NumberFormat('#,##0').format(total)} outstanding',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count ${count == 1 ? 'debt' : 'debts'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone Extra Income tile — thin purple outline.
/// Purely informational; does not feed any budget/income calculation.
class _ExtraIncomeCard extends StatelessWidget {
  final double total;
  final int count;
  final VoidCallback? onTap;

  const _ExtraIncomeCard({
    required this.total,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: 1.0,
        child: Container(
          constraints: const BoxConstraints(minHeight: 125),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(AppColors.isDarkMode ? 0.15 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Extra Income',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${NumberFormat('#,##0').format(total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$count ${count == 1 ? 'entry' : 'entries'}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final Widget child;

  const _BentoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.isDarkMode
              ? const Color(0xFF2D2A3A)
              : const Color(0xFFE5E7EB),
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
