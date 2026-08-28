import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Premium clay card with claymorphism depth — adaptive Dark + Light themes.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Border? border;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 24,
    this.onTap,
    this.hasShadow = true,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: hasShadow ? AppShadows.raised : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Subtle clay inner highlight
            if (hasShadow && gradient == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: AppShadows.clayInnerHighlight,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Gradient card for premium look with clay depth
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      borderRadius: borderRadius,
      gradient: gradient ?? AppColors.primaryGradient,
      onTap: onTap,
      child: child,
    );
  }
}
