import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Tactile claymorphism button with physical press interaction (Dark + Light).
///
/// Primary button uses a raised clay surface with purple accent.
/// Outlined button uses a neutral clay surface with primary border.
/// Press state: reduced shadow + subtle scale-down for tactile feedback.
class ClayButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;

  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 52,
  });

  const ClayButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 52,
  }) : isOutlined = true;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
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

    Widget childWidget;
    if (widget.isLoading) {
      childWidget = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.isOutlined ? AppColors.primary : fgColor,
        ),
      );
    } else if (widget.icon != null) {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 18, color: widget.isOutlined ? AppColors.primary : fgColor),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: widget.isOutlined ? AppColors.primary : fgColor,
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
          color: widget.isOutlined ? AppColors.primary : fgColor,
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
          transform: _isPressed
              ? (Matrix4.identity()..scale(0.98))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          width: widget.width ?? double.infinity,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: _isPressed ? AppShadows.pressed : AppShadows.soft,
          ),
          child: childWidget,
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
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
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
          boxShadow: _isPressed || isDisabled ? AppShadows.pressed : AppShadows.raised,
        ),
        child: childWidget,
      ),
    );
  }
}

// ─── Backward Compatibility ──────────────────────────────────────────────────

/// Legacy alias — wraps [ClayButton] for backward compatibility.
class SkeuoButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ClayButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: isOutlined,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      width: width,
      height: height,
    );
  }
}
