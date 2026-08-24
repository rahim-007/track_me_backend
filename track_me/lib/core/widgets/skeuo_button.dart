import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Adaptive tactile button with physical press interaction (Dark + Light).
class SkeuoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;

  const SkeuoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
  });

  const SkeuoButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
  }) : isOutlined = true;

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final baseBg = widget.backgroundColor ?? AppColors.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    final transform = _isPressed
        ? (Matrix4.identity()..translate(0.0, 2.0, 0.0))
        : Matrix4.identity();

    Widget childWidget;
    if (widget.isLoading) {
      childWidget = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: fgColor,
        ),
      );
    } else if (widget.icon != null) {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    } else {
      childWidget = Text(
        widget.label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: fgColor,
          letterSpacing: 0.2,
        ),
      );
    }

    if (widget.isOutlined) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          transform: transform,
          width: widget.width ?? double.infinity,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: _isPressed ? null : AppShadows.small,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: AppColors.primary),
            child: IconTheme(
              data: IconThemeData(color: AppColors.primary),
              child: childWidget,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: transform,
        width: widget.width ?? double.infinity,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceElevated
              : (_isPressed
                  ? Color.alphaBlend(Colors.black26, baseBg)
                  : baseBg),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: _isPressed
                ? Colors.transparent
                : AppColors.topBevelHighlight,
            width: 1,
          ),
          boxShadow: _isPressed || isDisabled ? null : AppShadows.medium,
        ),
        child: childWidget,
      ),
    );
  }
}
