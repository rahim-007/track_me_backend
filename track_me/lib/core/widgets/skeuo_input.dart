import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Inset claymorphism input container with focus state glow (Dark + Light).
///
/// The input appears visually pressed into the surface with a subtle inner
/// shadow. Focus state adds a purple accent border with soft glow.
class ClayInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final int maxLines;
  final bool readOnly;

  const ClayInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  State<ClayInput> createState() => _ClayInputState();
}

class _ClayInputState extends State<ClayInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceInset,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.6)
                  : Colors.transparent,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    ...AppShadows.inset,
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.10),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : AppShadows.inset,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Backward Compatibility ──────────────────────────────────────────────────

/// Legacy alias — wraps [ClayInput] for backward compatibility.
class SkeuoInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final int maxLines;
  final bool readOnly;

  const SkeuoInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInput(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      maxLines: maxLines,
      readOnly: readOnly,
    );
  }
}
