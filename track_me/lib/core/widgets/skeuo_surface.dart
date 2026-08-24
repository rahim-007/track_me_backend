import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

enum SkeuoSurfaceMode { raised, inset, flat, glass }

/// Core adaptive skeuomorphic surface implementing physical depth levels
/// with full Dark + Light mode support.
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

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (mode) {
      case SkeuoSurfaceMode.raised:
        content = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: AppColors.topBevelHighlight,
              width: 1,
            ),
            boxShadow: AppShadows.medium,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );
        break;

      case SkeuoSurfaceMode.inset:
        content = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surfaceInset,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: AppColors.isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 12,
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
        break;

      case SkeuoSurfaceMode.glass:
        content = Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.navBackground,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: border ?? Border.all(
                    color: AppColors.isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                  boxShadow: AppShadows.large,
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        );
        break;

      case SkeuoSurfaceMode.flat:
      default:
        content = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );
        break;
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
