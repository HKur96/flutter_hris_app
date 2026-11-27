import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Modular Input Text Field sesuai Tahap 1 Design Foundation.
/// Dilengkapi label terpisah, asterisk wajib, pesan helper / error kontekstual, dan dukungan monospace.
class AppTextField extends StatefulWidget {
  final String? label;
  final bool isRequired;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool isPassword;
  final bool isMonospace;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final double verticalPadding;
  final EdgeInsetsGeometry? contentPadding;
  final bool? isDense;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TapRegionCallback? onTapOutside;

  const AppTextField({
    super.key,
    this.label,
    this.isRequired = false,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.isPassword = false,
    this.isMonospace = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.verticalPadding = 10,
    this.contentPadding,
    this.isDense,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.validator,
    this.onTapOutside,
    this.suffixText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword || widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    TextStyle textStyle = widget.isMonospace
        ? GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
          )
        : GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Header
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              text: widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.statusDanger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Input Container
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: _obscured,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onTapOutside: widget.onTapOutside,
          style: textStyle,
          textAlign: widget.textAlign,
          textCapitalization: widget.textCapitalization,
          decoration: InputDecoration(
            hintText: widget.hintText,

            hintStyle: widget.isMonospace
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  )
                : GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            suffixText: widget.suffixText,
            suffixStyle: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : const Color(0xFFF1F5F9),
            isDense: widget.isDense,
            contentPadding:
                widget.contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: widget.verticalPadding,
                ),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      child: widget.prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 44,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscured = !_obscured;
                      });
                    },
                  )
                : widget.suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(
                color: hasError ? AppColors.statusDanger : AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(
                color: hasError ? AppColors.statusDanger : AppColors.primary,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
          ),
        ),

        // Contextual Helper / Error Row
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.statusDanger,
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.statusDanger,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null &&
            widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
