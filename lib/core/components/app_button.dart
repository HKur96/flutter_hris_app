// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, destructive, destructiveOutlined }

/// Modular Button Component untuk KaryaHR Mobile (Tahap 1 Design Foundation).
/// Memenuhi standar aksesibilitas smartphone dengan touch target 44px - 48px.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 46.0,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 46.0,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 46.0,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 46.0,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.destructiveOutlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 46.0,
  }) : variant = AppButtonVariant.destructiveOutlined;

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = effectiveDisabled
            ? const Color(0xFFF1F5F9)
            : AppColors.primary;
        foregroundColor = effectiveDisabled
            ? AppColors.textMuted
            : Colors.white;
        borderSide = effectiveDisabled
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none;
        break;

      case AppButtonVariant.secondary:
        backgroundColor = effectiveDisabled
            ? const Color(0xFFF8FAFC)
            : AppColors.surface;
        foregroundColor = effectiveDisabled
            ? AppColors.textMuted
            : AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
        break;

      case AppButtonVariant.destructive:
        backgroundColor = effectiveDisabled
            ? const Color(0xFFF1F5F9)
            : AppColors.statusDanger;
        foregroundColor = effectiveDisabled
            ? AppColors.textMuted
            : Colors.white;
        borderSide = BorderSide.none;
        break;

      case AppButtonVariant.destructiveOutlined:
        backgroundColor = effectiveDisabled
            ? const Color(0xFFF8FAFC)
            : AppColors.surface;
        foregroundColor = effectiveDisabled
            ? AppColors.textMuted
            : AppColors.statusDanger;
        borderSide = const BorderSide(color: AppColors.statusDanger, width: 1);
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: effectiveDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          splashColor: variant == AppButtonVariant.primary
              ? AppColors.primaryDark.withOpacity(0.2)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: borderSide != BorderSide.none
                  ? Border.fromBorderSide(borderSide)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                ] else if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: foregroundColor, size: 18),
                    child: icon!,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
