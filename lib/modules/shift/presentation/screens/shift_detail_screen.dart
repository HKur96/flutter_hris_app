import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/config/enum.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../domain/entity/shift.dart';
import '../provider/shift_provider.dart';
import 'add_edit_shift_screen.dart';

/// Screen Detail Master Shift (Mockup 04 untuk Admin/Owner & Mockup 05 untuk Staff Read-Only).
/// Menampilkan spesifikasi teknis jam kerja, gross & net duration, status aktif/nonaktif,
/// serta aksi edit dan toggle status deactivation sesuai standar GAS Modul 3.
class ShiftDetailScreen extends StatefulWidget {
  final Shift shift;

  const ShiftDetailScreen({super.key, required this.shift});

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  Future<void> _confirmToggleStatus(Shift currentShift) async {
    final willDeactivate = currentShift.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Text(
          willDeactivate ? 'Nonaktifkan Shift?' : 'Aktifkan Kembali Shift?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          willDeactivate
              ? 'Shift "${currentShift.name}" tidak akan dapat dipilih lagi dalam plotting roster baru. Riwayat presensi terdahulu tetap aman.'
              : 'Shift "${currentShift.name}" akan kembali aktif dan dapat dipilih untuk roster kerja karyawan.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willDeactivate
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              willDeactivate ? 'Ya, Nonaktifkan' : 'Ya, Aktifkan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ShiftProvider>();
      final ok = await provider.toggleShiftStatus(
        currentShift.id,
        !currentShift.isActive,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willDeactivate
                  ? 'Shift berhasil dinonaktifkan.'
                  : 'Shift berhasil diaktifkan kembali.',
              style: GoogleFonts.inter(fontSize: 12.5),
            ),
            backgroundColor: willDeactivate
                ? AppColors.textSecondary
                : AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Gagal memperbarui status shift.',
              style: GoogleFonts.inter(fontSize: 12.5),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.select<AuthProvider, Role>(
      (p) => p.user?.role ?? Role.employee,
    );
    final bool canManage = userRole == Role.owner || userRole == Role.admin;

    final shiftProvider = context.watch<ShiftProvider>();
    // Sinkronkan data shift terupdate dari provider
    final currentShift = shiftProvider.shifts.firstWhere(
      (s) => s.id == widget.shift.id,
      orElse: () => widget.shift,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          canManage ? 'Detail Jadwal Shift' : 'Informasi Shift Saya',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: canManage
                    ? _buildAdminDetailBody(currentShift)
                    : _buildEmployeeDetailBody(currentShift),
              ),
            ),

            // Bottom Action Bar 48dp Sesuai Role
            if (canManage)
              _buildAdminBottomActions(currentShift)
            else
              _buildEmployeeBottomActions(),
          ],
        ),
      ),
    );
  }

  /// Body Tampilan Detail untuk Admin / Owner (Mockup 04)
  Widget _buildAdminDetailBody(Shift shift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Card (ID, Nama Shift, Status & Jam Kerja Tag)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: shift.isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: shift.isActive
                          ? AppColors.primaryLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(
                        color: shift.isActive
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      shift.isActive ? 'AKTIF' : 'NONAKTIF',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: shift.isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          shift.formattedTimeRange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (shift.isCrossDayOvernight)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.nights_stay_rounded,
                            size: 15,
                            color: Color(0xFF7E22CE),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Lintas Hari (Overnight)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Parameters Card (Spesifikasi Teknis Jam Kerja)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPESIFIKASI TEKNIS JAM KERJA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              // Grid 1: Jam Masuk & Jam Pulang
              Row(
                children: [
                  Expanded(
                    child: _buildParameterTile(
                      label: 'Jam Masuk',
                      value: '${shift.startTime} WIB',
                      icon: Icons.login_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildParameterTile(
                      label: 'Jam Pulang',
                      value:
                          '${shift.endTime} WIB${shift.isCrossDayOvernight ? " (+1)" : ""}',
                      icon: Icons.logout_rounded,
                      iconColor: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Grid 2: Durasi Istirahat & Toleransi Terlambat
              Row(
                children: [
                  Expanded(
                    child: _buildParameterTile(
                      label: 'Durasi Istirahat',
                      value: '${shift.breakMinutes} Menit',
                      icon: Icons.free_breakfast_outlined,
                      iconColor: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildParameterTile(
                      label: 'Toleransi Terlambat',
                      value: '${shift.lateToleranceMinutes} Menit',
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // 3. Durasi Kerja API Contract Card
        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(AppRadius.medium),
            strokeWidth: 0.6,
            dashPattern: const [6, 4],
            color: Colors.grey,
            strokeCap: StrokeCap.round,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Durasi Kotor (gross):',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${shift.calculatedGrossMinutes} Menit (${shift.formattedGrossHours})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Durasi Kerja Bersih (net):',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${shift.calculatedNetMinutes} Menit (${shift.formattedNetHours})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Body Tampilan Detail untuk Employee / Staff Read-Only (Mockup 05)
  Widget _buildEmployeeDetailBody(Shift shift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Friendly Notice Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Penjadwalan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jam kerja dan toleransi kehadiran ditentukan oleh operasional HR perusahaan Anda.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF1E40AF),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Core Shift Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TEMPLATE SHIFT PENUGASAN',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shift.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Kerja Resmi',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shift.formattedTimeRange,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        shift.isActive ? 'AKTIF' : 'NONAKTIF',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ketentuan Kehadiran Overview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ketentuan Kehadiran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              _buildSimpleRow(
                label: 'Waktu Istirahat Resmi',
                value: '${shift.breakMinutes} Menit',
              ),
              const Divider(height: 16, color: AppColors.border),
              _buildSimpleRow(
                label: 'Toleransi Batas Hadir',
                value: 'Maks. ${shift.lateToleranceMinutes} Menit',
                valueColor: AppColors.primary,
              ),
              const Divider(height: 16, color: AppColors.border),
              _buildSimpleRow(
                label: 'Tipe Jadwal',
                value: shift.isCrossDayOvernight
                    ? 'Lintas Tengah Malam (+1)'
                    : 'Hari Sama (Reguler)',
              ),
              const Divider(height: 16, color: AppColors.border),
              _buildSimpleRow(
                label: 'Target Efektif Harian',
                value: shift.formattedNetHours,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParameterTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Sticky Bottom Actions untuk Admin/Owner (Mockup 04)
  Widget _buildAdminBottomActions(Shift shift) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              child: Text(
                'Ubah Template Shift',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditShiftScreen(shift: shift),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Selector<ShiftProvider, bool>(
            selector: (_, p) => p.isLoading,
            builder: (context, isLoading, _) {
              return SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: shift.isActive
                        ? AppColors.error
                        : AppColors.primary,
                    side: BorderSide(
                      color: shift.isActive
                          ? const Color(0xFFFECACA)
                          : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () => _confirmToggleStatus(shift),
                  child: Text(
                    isLoading
                        ? 'Memproses...'
                        : shift.isActive
                        ? 'Nonaktifkan Shift'
                        : 'Aktifkan Kembali Shift',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Actions untuk Employee Read-Only (Mockup 05)
  Widget _buildEmployeeBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Kembali ke Jadwal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hak Akses: EMPLOYEE (Read-Only Isolated)',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
