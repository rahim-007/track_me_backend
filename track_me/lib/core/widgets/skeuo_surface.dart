import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Clay surface elevation levels.
enum ClaySurfaceLevel { soft, raised, elevated, inset, flat }

/// Core claymorphism surface widget implementing physical depth levels
/// with full Dark + Light mode support.
///
/// Use named constructors for convenience:
/// ```dart
/// ClaySurface.soft(child: ...)    // L1 — backgrounds, nav, secondary
/// ClaySurface.raised(child: ...)  // L2 — cards, items, stat cards
/// ClaySurface.elevated(child: ...) // L3 — hero, primary buttons, FABs
/// ClaySurface.inset(child: ...)   // Recessed — inputs, pressed state
/// ```
class ClaySurface extends StatelessWidget {
  final Widget child;
  final ClaySurfaceLevel level;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const ClaySurface({
    super.key,
    required this.child,
    this.level = ClaySurfaceLevel.raised,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  });

  const ClaySurface.soft({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : level = ClaySurfaceLevel.soft;

  const ClaySurface.raised({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : level = ClaySurfaceLevel.raised;

  const ClaySurface.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.large,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : level = ClaySurfaceLevel.elevated;

  const ClaySurface.inset({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : level = ClaySurfaceLevel.inset;

  List<BoxShadow> _shadowForLevel() {
    switch (level) {
      case ClaySurfaceLevel.soft:
        return AppShadows.soft;
      case ClaySurfaceLevel.raised:
        return AppShadows.raised;
      case ClaySurfaceLevel.elevated:
        return AppShadows.elevated;
      case ClaySurfaceLevel.inset:
        return AppShadows.inset;
      case ClaySurfaceLevel.flat:
        return [];
    }
  }

  Color _colorForLevel() {
    switch (level) {
      case ClaySurfaceLevel.soft:
        return backgroundColor ?? AppColors.surface;
      case ClaySurfaceLevel.raised:
        return backgroundColor ?? AppColors.surface;
      case ClaySurfaceLevel.elevated:
        return backgroundColor ?? AppColors.surfaceElevated;
      case ClaySurfaceLevel.inset:
        return backgroundColor ?? AppColors.surfaceInset;
      case ClaySurfaceLevel.flat:
        return backgroundColor ?? AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final surfaceColor = _colorForLevel();
    final shadows = _shadowForLevel();

    Widget content;

    if (level == ClaySurfaceLevel.inset) {
      // Inset surfaces use inner shadow simulation
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: border,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Inner shadow gradient at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 10,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppShadows.insetTopShadow,
                  ),
                ),
              ),
              Padding(
                padding: padding ?? const EdgeInsets.all(14),
                child: child,
              ),
            ],
          ),
        ),
      );
    } else {
      // Standard clay surfaces with outer shadow + inner highlight
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: border,
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Subtle inner highlight (only for raised and elevated)
              if (level == ClaySurfaceLevel.raised ||
                  level == ClaySurfaceLevel.elevated)
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
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

// ─── Backward Compatibility ──────────────────────────────────────────────────

/// Legacy alias — maps to [ClaySurfaceLevel].
enum SkeuoSurfaceMode { raised, inset, flat, glass }

/// Legacy alias — wraps [ClaySurface] for backward compatibility.
///
/// All existing usages of `SkeuoSurface` will continue to work.
class SkeuoSurface extends StatelessWidget {
  final Widget child;
  final SkeuoSurfaceMode mode;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const SkeuoSurface({
    super.key,
    required this.child,
    this.mode = SkeuoSurfaceMode.raised,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  });

  const SkeuoSurface.inset({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : mode = SkeuoSurfaceMode.inset;

  const SkeuoSurface.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.large,
    this.backgroundColor,
    this.border,
    this.onTap,
  }) : mode = SkeuoSurfaceMode.glass;

  ClaySurfaceLevel _mapLevel() {
    switch (mode) {
      case SkeuoSurfaceMode.raised:
        return ClaySurfaceLevel.raised;
      case SkeuoSurfaceMode.inset:
        return ClaySurfaceLevel.inset;
      case SkeuoSurfaceMode.flat:
        return ClaySurfaceLevel.flat;
      case SkeuoSurfaceMode.glass:
        return ClaySurfaceLevel.elevated;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      level: _mapLevel(),
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      border: border,
      onTap: onTap,
      child: child,
    );
  }
}
