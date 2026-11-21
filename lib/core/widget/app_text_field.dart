import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hris_app/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextCapitalization textCapitalization;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormatter;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool obscureText;
  final Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextAlign textAlign;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
    this.textInputType,
    this.inputFormatter,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.focusNode,
    this.onChanged,
    this.textAlign = TextAlign.start,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textAlign: textAlign,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatter,
      textInputAction: textInputAction,
      keyboardType: textInputType,
      validator: validator,
      maxLines: maxLines,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: InputBorder.none,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}
