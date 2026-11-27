// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Modular Horizontal Smooth Slider untuk pengaturan Sistem Shift (Non-Aktif vs Aktif).
/// Menggunakan track kontras lembut, sliding pill putih beranimasi halus (M3/iOS style),
/// gesture swipe & tap, serta haptic feedback sesuai spesifikasi KaryaHR Mobile.
class AppShiftSlider extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? label;
  final bool isRequired;
  final bool showDescription;

  const AppShiftSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label,
    this.isRequired = false,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
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

        // Slider Track Container
        GestureDetector(
          onHorizontalDragUpdate: enabled
              ? (details) {
                  if (details.primaryDelta != null) {
                    if (details.primaryDelta! > 2 && !value) {
                      HapticFeedback.selectionClick();
                      onChanged(true);
                    } else if (details.primaryDelta! < -2 && value) {
                      HapticFeedback.selectionClick();
                      onChanged(false);
                    }
                  }
                }
              : null,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                // Smooth Animated Sliding Indicator Pill
                AnimatedAlign(
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppRadius.medium - 2,
                        ),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.8),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Option Labels Row
                Row(
                  children: [
                    Expanded(
                      child: _buildOption(
                        context: context,
                        isSelected: !value,
                        text: 'Non-Aktif',
                        onTap: () {
                          if (value && enabled) {
                            HapticFeedback.selectionClick();
                            onChanged(false);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildOption(
                        context: context,
                        isSelected: value,
                        text: 'Aktif',
                        onTap: () {
                          if (!value && enabled) {
                            HapticFeedback.selectionClick();
                            onChanged(true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (showDescription) ...[
          const SizedBox(height: 6),
          Text(
            value
                ? 'Fitur jadwal shift karyawan aktif dan dapat diatur oleh Admin.'
                : 'Fitur shift dinonaktifkan. Seluruh karyawan mengikuti jam kerja reguler toko.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required bool isSelected,
    required String text,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium - 2),
        splashColor: AppColors.primary.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
