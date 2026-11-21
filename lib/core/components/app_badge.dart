import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

enum AppBadgeType {
  pending,
  approved,
  rejected,
  cancelled,
  present,
  late,
  finalized,
  paid,
  active,
  inactive,
  custom,
}

/// Modular Status Badge Component sesuai Tahap 1 Design Foundation.
/// Memetakan status enum API Contract (Cuti, Presensi, Payroll, Kasbon).
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;
  final Color? customTextColor;
  final Color? customBgColor;
  final Color? customBorderColor;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.pending,
    this.customTextColor,
    this.customBgColor,
    this.customBorderColor,
  });

  const AppBadge.pending({
    super.key,
    this.label = 'PENDING',
  })  : type = AppBadgeType.pending,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.approved({
    super.key,
    this.label = 'APPROVED',
  })  : type = AppBadgeType.approved,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.rejected({
    super.key,
    this.label = 'REJECTED',
  })  : type = AppBadgeType.rejected,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.cancelled({
    super.key,
    this.label = 'CANCELLED',
  })  : type = AppBadgeType.cancelled,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.present({
    super.key,
    this.label = 'HADIR TEPAT WAKTU',
  })  : type = AppBadgeType.present,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.late({
    super.key,
    this.label = 'TERLAMBAT',
  })  : type = AppBadgeType.late,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.finalized({
    super.key,
    this.label = 'FINALIZED',
  })  : type = AppBadgeType.finalized,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.paid({
    super.key,
    this.label = 'PAID (TERBAYAR)',
  })  : type = AppBadgeType.paid,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.active({
    super.key,
    this.label = 'AKTIF',
  })  : type = AppBadgeType.active,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  const AppBadge.inactive({
    super.key,
    this.label = 'NONAKTIF',
  })  : type = AppBadgeType.inactive,
        customTextColor = null,
        customBgColor = null,
        customBorderColor = null;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (type) {
      case AppBadgeType.pending:
      case AppBadgeType.late:
        textColor = AppColors.statusWarning;
        bgColor = AppColors.statusWarningBg;
        borderColor = AppColors.statusWarningBorder;
        break;

      case AppBadgeType.approved:
      case AppBadgeType.paid:
      case AppBadgeType.present:
      case AppBadgeType.active:
        textColor = AppColors.statusSuccess;
        bgColor = AppColors.statusSuccessBg;
        borderColor = AppColors.statusSuccessBorder;
        break;

      case AppBadgeType.rejected:
        textColor = AppColors.statusDanger;
        bgColor = AppColors.statusDangerBg;
        borderColor = AppColors.statusDangerBorder;
        break;

      case AppBadgeType.cancelled:
      case AppBadgeType.inactive:
        textColor = const Color(0xFF334155);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        break;

      case AppBadgeType.finalized:
        textColor = AppColors.statusInfo;
        bgColor = AppColors.statusInfoBg;
        borderColor = AppColors.statusInfoBorder;
        break;

      case AppBadgeType.custom:
        textColor = customTextColor ?? AppColors.textPrimary;
        bgColor = customBgColor ?? AppColors.canvas;
        borderColor = customBorderColor ?? AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );
  }
}
