import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/attendance_history_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_in_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_out_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/today_attendance_screen.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/my_shift_schedule_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/components/components.dart';
import 'dashboard_quick_action.dart';

enum AttendanceCardState { standby, working, completed, holiday }

/// Screen C: Employee Dashboard (Self-Service Hub & Ergonomic Thumb Area)
/// Sesuai spesifikasi visual Stitch Tahap 1 Mobile HRIS UI/UX Design.
class EmployeeDashboardView extends StatefulWidget {
  final VoidCallback? onRefresh;
  final User? user;

  const EmployeeDashboardView({super.key, this.onRefresh, required this.user});

  @override
  State<EmployeeDashboardView> createState() => _EmployeeDashboardViewState();
}

class _EmployeeDashboardViewState extends State<EmployeeDashboardView> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  AttendanceCardState _attendanceState = AttendanceCardState.working;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatLiveClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

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
          // 1. Header Profil Karyawan
          _buildEmployeeProfileCard(context),
          const SizedBox(height: AppSpacing.space16),

          // 2. Primary Hero: Attendance Card (Ergonomic Thumb Tap)
          _buildAttendanceHeroCard(context),
          const SizedBox(height: AppSpacing.space20),

          // 3. Personal Financial & Rights Summary (Kasbon Aktif)
          _buildFinancialRightsSection(context),
          const SizedBox(height: AppSpacing.space20),

          // 4. Self-Service Action Grid (Layanan Mandiri)
          _buildSelfServiceActionsSection(context),
          const SizedBox(height: AppSpacing.space20),

          // 5. Recent Personal Log Activity (Aktivitas Saya)
          _buildPersonalActivitiesSection(context),
          const SizedBox(height: AppSpacing.space24),
        ],
      ),
    );
  }

  Widget _buildEmployeeProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'AP',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Agus Prasetyo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dapur & Produksi (Tetap)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'EMPLOYEE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift & Badge State
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyShiftScheduleScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Jadwal Shift Anda',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shift Pagi (08:00 — 17:00 WIB)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildStateBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),

          // Digital Live Clock & GPS Verification Box
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TodayAttendanceScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatLiveClock(_currentTime),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WIB',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pin_drop_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Radius Valid: 8m dari Toko Pusat',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _attendanceState == AttendanceCardState.working
                      ? 'Check-In tercatat: 06:55 WIB (Tepat Waktu)'
                      : _attendanceState == AttendanceCardState.standby
                      ? 'Siap melakukan rekam presensi masuk'
                      : _attendanceState == AttendanceCardState.completed
                      ? 'Presensi hari ini telah tuntas tercatat'
                      : 'Tidak ada shift hari ini (Libur berkala)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

          // Primary Bottom Ergonomic Button (Thumb Tap)
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildStateBadge() {
    switch (_attendanceState) {
      case AttendanceCardState.working:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Text(
            'Sedang Bekerja',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      case AttendanceCardState.standby:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Standby',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
      case AttendanceCardState.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brand100,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Text(
            'Selesai',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        );
      case AttendanceCardState.holiday:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Off Shift',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
    }
  }

  Widget _buildActionButton(BuildContext context) {
    if (_attendanceState == AttendanceCardState.standby) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          icon: const Icon(Icons.login_rounded, size: 20),
          label: Text(
            'Check-In Presensi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () async {
            final res = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClockInScreen()),
            );
            if (res == true && mounted) {
              setState(() {
                _attendanceState = AttendanceCardState.working;
              });
            }
          },
        ),
      );
    } else if (_attendanceState == AttendanceCardState.working) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.canvas,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            'Check-Out Sekarang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () async {
            final res = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClockOutScreen()),
            );
            if (res == true && mounted) {
              setState(() {
                _attendanceState = AttendanceCardState.completed;
              });
            }
          },
        ),
      );
    } else if (_attendanceState == AttendanceCardState.completed) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.canvas,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          icon: const Icon(
            Icons.task_alt_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          label: Text(
            'Presensi Hari Ini Selesai',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: null,
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          onPressed: null,
          child: Text(
            'Hari Libur Berkala',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFinancialRightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMASI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kasbon Aktif (Termin 02/04)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sisa: Rp 1.500.000',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () {
                    _showFeedback(context, 'Detail angsuran kasbon karyawan');
                  },
                  child: Text(
                    'Detail',
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

  Widget _buildSelfServiceActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAYANAN MANDIRI KARYAWAN',
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
                icon: Icons.edit_calendar_outlined,
                label: 'Ajukan Cuti',
                onTap: () {
                  _showFeedback(context, 'Membuka formulir pengajuan cuti');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.more_time_rounded,
                label: 'Lembur',
                onTap: () {
                  _showFeedback(context, 'Membuka formulir pengajuan lembur');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'Slip Gaji',
                onTap: () {
                  _showFeedback(context, 'Membuka riwayat slip gaji bulanan');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: DashboardQuickAction(
                icon: Icons.request_quote_outlined,
                label: 'Kasbon',
                onTap: () {
                  _showFeedback(context, 'Membuka formulir kasbon karyawan');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKTIVITAS SAYA',
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
                text: 'Presensi Masuk Berhasil',
                time: '06:55 WIB',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AttendanceHistoryScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildActivityRow(
                dotColor: AppColors.textSecondary,
                text: 'Pengajuan Cuti Disetujui HR',
                time: 'Kemarin',
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
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
