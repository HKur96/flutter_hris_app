import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/components/components.dart';
import 'dashboard_quick_action.dart';
import 'dashboard_stat_tile.dart';

/// Screen A: Owner Dashboard (Macro Level & High-Stake Approvals)
/// Sesuai spesifikasi visual Stitch Tahap 1 Mobile HRIS UI/UX Design.
class OwnerDashboardView extends StatelessWidget {
  final User? user;
  final VoidCallback? onRefresh;

  const OwnerDashboardView({super.key, this.onRefresh, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Profil Owner
          _buildOwnerProfileCard(context),
          const SizedBox(height: AppSpacing.space16),

          // 2. Macro Company Overview (2x2 Grid)
          _buildMacroOverviewSection(context),
          const SizedBox(height: AppSpacing.space20),

          // 3. Pending Approvals & Actions (Otorisasi Tertunda Owner)
          _buildPendingApprovalsSection(context),
          const SizedBox(height: AppSpacing.space20),

          // 4. Quick Operational Grid (4 Kolom Akses Cepat)
          _buildQuickActionsSection(context),
          const SizedBox(height: AppSpacing.space20),

          // 5. Recent Activities / Jejak Operasional Terkini
          _buildRecentActivitiesSection(context),
          const SizedBox(height: AppSpacing.space24),
        ],
      ),
    );
  }

  Widget _buildOwnerProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'OW',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user?.storeName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'METRIK ORGANISASI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.space10,
          crossAxisSpacing: AppSpacing.space10,
          childAspectRatio: 1.45,
          children: const [
            DashboardStatTile(
              label: 'Total Karyawan',
              value: '48 Jiwa',
              subtitle: '42 Aktif · 6 Cuti/Off',
            ),
            DashboardStatTile(
              label: 'Presensi Hari Ini',
              value: '42 / 48',
              valueColor: AppColors.primary,
              subtitle: '87.5% Tepat Waktu',
            ),
            DashboardStatTile(
              label: 'Otorisasi Menunggu',
              value: '5 Item',
              subtitle: '2 Cuti · 1 Lembur · 2 Kasbon',
            ),
            DashboardStatTile(
              label: 'Liabilitas Payroll Mei',
              value: 'Rp 148.650.000',
              subtitle: 'Status Draft Final',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OTORISASI TERTUNDA (OWNER)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusWarningBg,
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: AppColors.statusWarningBorder),
              ),
              child: Text(
                '3 Mendesak',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusWarning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),

        // Item 1: Kasbon #ADV-012
        Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengajuan Kasbon #ADV-012',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ahmad Fauzi (Gudang)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rp 5.000.000',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space8),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  'Melebihi batas limit supervisor. Memerlukan otorisasi plafon Owner langsung.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 38),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          _showFeedback(
                            context,
                            'Kasbon Ahmad Fauzi telah disetujui',
                          );
                        },
                        child: Text(
                          'Tinjau & Setujui',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () {
                        _showFeedback(context, 'Pengajuan Kasbon ditolak');
                      },
                      child: Text(
                        'Tolak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space10),

        // Item 2: Batch Payroll Final
        Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Payroll Mei 2026',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '42 Slip Gaji Terverifikasi HR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Draft',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text(
                    'Otorisasi & Kunci Penggajian',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    _showFeedback(
                      context,
                      'Batch Payroll Mei telah diotorisasi & dikunci.',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space10),

        // Item 3: Cuti Tahunan
        Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agus Prasetyo — Cuti Tahunan (3 Hari)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dapur & Produksi · Mulai 02 Juni',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.brand200),
                    backgroundColor: AppColors.brand50,
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () {
                    _showFeedback(
                      context,
                      'Cuti tahunan Agus Prasetyo disetujui',
                    );
                  },
                  child: Text(
                    'Setujui',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKSES OPERASIONAL CEPAT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        Row(
          children: [
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.badge_outlined,
                label: 'Kelola Staf',
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(AppConstants.kRouteAdminShell);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.payments_outlined,
                label: 'Payroll',
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(AppConstants.kRouteAdminShell);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Kasbon',
                onTap: () {
                  _showFeedback(context, 'Membuka menu Kasbon UMKM');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.history_rounded,
                label: 'Audit Log',
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(AppConstants.kRouteAdminShell);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JEJAK OPERASIONAL TERKINI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildActivityRow(
                dotColor: AppColors.primary,
                text: 'Pencairan Kasbon Disetujui (Hendra Wijaya)',
                time: '10:15 WIB',
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildActivityRow(
                dotColor: AppColors.textSecondary,
                text: 'Finalisasi Draf Payroll Mei (Batch 42 Staf)',
                time: '08:30 WIB',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required Color dotColor,
    required String text,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space10,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
