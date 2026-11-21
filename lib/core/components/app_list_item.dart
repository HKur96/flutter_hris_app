import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_badge.dart';

/// Modular List Item Karyawan sesuai Tahap 1 Design Foundation.
/// Dilengkapi inisial avatar (BS/SR), nama, subtitle jabatan/shift, badge status, & chevron.
class AppEmployeeListItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  const AppEmployeeListItem({
    super.key,
    required this.name,
    required this.subtitle,
    this.isActive = true,
    this.onTap,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.canvas,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Avatar Inisial
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brand50 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: isActive ? AppColors.brand200 : const Color(0xFFCBD5E1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.brand800 : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),

              // Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),

              // Status Badge
              AppBadge(
                label: isActive ? 'AKTIF' : 'NONAKTIF',
                type: isActive ? AppBadgeType.active : AppBadgeType.inactive,
              ),
              const SizedBox(width: AppSpacing.space8),

              // Trailing Chevron
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modular List Item Pengajuan Cuti / Izin / Lembur sesuai Tahap 1.
class AppLeaveListItem extends StatelessWidget {
  final String title;
  final String dateRange;
  final String note;
  final String submitDate;
  final String? approvedBy;
  final AppBadgeType statusType;
  final String statusLabel;
  final VoidCallback? onTap;

  const AppLeaveListItem({
    super.key,
    required this.title,
    required this.dateRange,
    required this.note,
    required this.submitDate,
    this.approvedBy,
    required this.statusType,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.canvas,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  AppBadge(
                    label: statusLabel,
                    type: statusType,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$dateRange • $note',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    approvedBy != null
                        ? 'Disetujui oleh: $approvedBy'
                        : 'Diajukan: $submitDate',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
