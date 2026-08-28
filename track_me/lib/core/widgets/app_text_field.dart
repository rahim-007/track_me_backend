import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Premium clay text field with inset appearance.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int maxLines;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixWidget,
    this.inputFormatters,
    this.readOnly = false,
    this.maxLines = 1,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary.withOpacity(0.5)
              : Colors.transparent,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                ...AppShadows.inset,
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : AppShadows.inset,
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        inputFormatters: widget.inputFormatters,
        readOnly: widget.readOnly,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isFocused ? AppColors.primary : AppColors.textSecondary,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 20, color: _isFocused ? AppColors.primary : AppColors.textSecondary)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffixWidget,
          // Remove all borders — the outer AnimatedContainer handles borders
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: false,
        ),
      ),
    );
  }
}
