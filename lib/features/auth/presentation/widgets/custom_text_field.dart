import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String hintText;
  final Widget? prefix;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final Widget? trailingLabel;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.label,
    required this.hintText,
    this.prefix,
    this.isPassword = false,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.trailingLabel,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.trailingLabel != null) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              if (widget.trailingLabel != null) widget.trailingLabel!,
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                Container(
                  width: 1,
                  height: 24,
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: _obscureText,
                  keyboardType: widget.keyboardType,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    counterText: '', // Hide the max length counter
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: widget.isPassword
                        ? IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
