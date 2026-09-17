import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/cashflow_models.dart';

/// Signature Gradient Hero Financial Card with wave texture, net balance,
/// income/outflow metrics, and sub-account breakdown (Bank, Cash, Credit Card).
///
/// Supports [isCompact] = true for dense dashboard placement, and [isCompact] = false
/// for full hero view on the Cash Flow screen.
class CashFlowHeroCard extends StatelessWidget {
  final CashFlowPeriodModel period;
  final VoidCallback? onTap;
  final bool isCompact;

  const CashFlowHeroCard({
    super.key,
    required this.period,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = isCompact ? _buildCompactCard(context) : _buildFullCard(context);

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return RepaintBoundary(child: card);
  }

  // ─── Compact Mode (Optimized for Dashboard) ──────────────────────────────────
  Widget _buildCompactCard(BuildContext context) {
    final net = period.netCashFlow;
    final isPositive = net >= 0;
    final formattedNet = '${isPositive ? '+' : ''}₹${NumberFormat('#,##0').format(net)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5848D6),
        gradient: const LinearGradient(
          colors: [Color(0xFF5848D6), Color(0xFF4930D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5848D6).withOpacity(0.30),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WaveBackgroundPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: NET CASH FLOW Label & Positive/Deficit Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_graph_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.90),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NET CASH FLOW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: Colors.white.withOpacity(0.90),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPositive ? 'Positive' : 'Deficit',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // Middle Row: Amount on Left, Income/Outflow badges on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formattedNet,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _compactFlowChip(
                            amount: '+₹${NumberFormat('#,##0').format(period.totalIncome)}',
                            color: const Color(0xFF34D399),
                            icon: Icons.south_west_rounded,
                          ),
                          const SizedBox(width: 8),
                          _compactFlowChip(
                            amount: '-₹${NumberFormat('#,##0').format(period.totalOutflow)}',
                            color: const Color(0xFFF87171),
                            icon: Icons.north_east_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bottom Row: Slim Sub-Account Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _compactAccountItem(
                          label: 'Bank',
                          value: period.closingBank,
                          icon: Icons.account_balance_rounded,
                        ),
                        Container(width: 1, height: 16, color: Colors.white.withOpacity(0.22)),
                        _compactAccountItem(
                          label: 'Cash',
                          value: period.closingCash,
                          icon: Icons.payments_rounded,
                        ),
                        Container(width: 1, height: 16, color: Colors.white.withOpacity(0.22)),
                        _compactAccountItem(
                          label: 'Card',
                          value: period.closingCreditCard,
                          icon: Icons.credit_card_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactFlowChip({
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactAccountItem({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        Text(
          '₹${NumberFormat('#,##0').format(value)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Full Mode (Hero on Cash Flow Screen) ────────────────────────────────────
  Widget _buildFullCard(BuildContext context) {
    final net = period.netCashFlow;
    final isPositive = net >= 0;
    final formattedNet = '${isPositive ? '+' : ''}₹${NumberFormat('#,##0').format(net)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5848D6),
        gradient: const LinearGradient(
          colors: [Color(0xFF5848D6), Color(0xFF4930D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5848D6).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // Subtle Flowing Wave Texture Background
            Positioned.fill(
              child: CustomPaint(
                painter: _WaveBackgroundPainter(),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: NET CASH FLOW Label & Positive/Deficit Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NET CASH FLOW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPositive ? 'Positive' : 'Deficit',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Main Net Cash Flow Amount
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formattedNet,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Income & Outflow Summary Row
                  Row(
                    children: [
                      // Income
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '+₹${NumberFormat('#,##0').format(period.totalIncome)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Subtle Vertical Divider
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.25),
                      ),
                      const SizedBox(width: 16),
                      // Outflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outflow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '-₹${NumberFormat('#,##0').format(period.totalOutflow)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Bottom Sub-Account Balance Cards (Bank, Cash, Credit Card)
                  Row(
                    children: [
                      _buildAccountSubCard(
                        label: 'Bank',
                        value: period.closingBank,
                        icon: Icons.account_balance_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAccountSubCard(
                        label: 'Cash',
                        value: period.closingCash,
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAccountSubCard(
                        label: 'Credit Card',
                        value: period.closingCreditCard,
                        icon: Icons.credit_card_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSubCard({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${NumberFormat('#,##0').format(value)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Subtle Flowing Wave Background Texture
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.cubicTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.65, size.height * 0.7,
      size.width, size.height * 0.3,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.35, size.height * 0.3,
      size.width * 0.75, size.height * 0.95,
      size.width, size.height * 0.55,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
