import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FormulaFlowWidget extends StatelessWidget {
  const FormulaFlowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      _FlowStep(emoji: '💰', label: 'Monthly Income', color: Color(0xFF7C3AED)),
      _FlowStep(emoji: '🏦', label: 'Savings Target', color: Color(0xFF10B981)),
      _FlowStep(emoji: '💳', label: 'Spendable Budget', color: Color(0xFFF97316)),
      _FlowStep(emoji: '📅', label: 'Daily Goal', color: Color(0xFF3B82F6)),
      _FlowStep(emoji: '📊', label: 'Track Cash Flow', color: Color(0xFF6366F1)),
      _FlowStep(emoji: '📈', label: 'Profit / Loss', color: Color(0xFFEC4899)),
      _FlowStep(emoji: '🎯', label: 'Monthly Savings', color: Color(0xFF059669)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: step.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(step.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: step.color,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: step.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                steps[i].color.withOpacity(0.3),
                                steps[i + 1].color.withOpacity(0.3),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FlowStep {
  final String emoji;
  final String label;
  final Color color;

  const _FlowStep({
    required this.emoji,
    required this.label,
    required this.color,
  });
}
