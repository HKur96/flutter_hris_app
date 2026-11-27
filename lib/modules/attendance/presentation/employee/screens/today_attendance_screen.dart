import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/attendance_history_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_in_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_out_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 01 & 10 — Presensi Hari Ini & Empty State
/// Sesuai spesifikasi Stitch Stage 6: Attendance (KaryaHR Mobile).
class TodayAttendanceScreen extends StatefulWidget {
  final bool showAppBar;

  const TodayAttendanceScreen({super.key, this.showAppBar = true});

  @override
  State<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends State<TodayAttendanceScreen> {
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchTodayAttendance();
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'KH';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = _getInitials(user?.name ?? '');

    final content = Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingToday) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final session = provider.todayAttendance;
        final hasShift = session?.shiftName.isNotEmpty == true;

        // 10. EMPTY STATE: NO SHIFT TODAY (If shift is absent or specifically marked off)
        if (!hasShift && session == null && provider.todayError == null) {
          return _buildNoShiftEmptyState(provider);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => provider.fetchTodayAttendance(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Shift Hari Ini
                _buildShiftInfoCard(session?.shiftName),
                const SizedBox(height: AppSpacing.space16),

                // Status Kartu Presensi Hari Ini
                _buildTodayStatusCard(provider),
                const SizedBox(height: AppSpacing.space24),

                // Action Button: Contextual Clock-In / Clock-Out
                _buildContextualActionButton(provider),
                const SizedBox(height: AppSpacing.space12),

                // Link Riwayat Presensi
                Center(
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Lihat Riwayat Presensi Lengkap',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AttendanceHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormatter.dateTimeToString(_today, 'EEEE, dd MMM yyyy'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: content,
    );
  }

  /// Info Shift Hari Ini Card
  Widget _buildShiftInfoCard(String? shiftName) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Shift Anda',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  shiftName?.isNotEmpty == true ? shiftName! : 'Shift Pagi',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '08:00 – 17:00',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'WIB',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Status Kartu Presensi Hari Ini
  Widget _buildTodayStatusCard(AttendanceProvider provider) {
    final session = provider.todayAttendance;
    final isClockedIn = session?.checkIn != null;
    final isClockedOut = session?.checkOut != null;

    final inTimeStr = isClockedIn
        ? DateFormatter.dateTimeToString(session!.checkIn!, 'HH:mm:ss')
        : '--:--:--';
    final outTimeStr = isClockedOut
        ? DateFormatter.dateTimeToString(session!.checkOut!, 'HH:mm:ss')
        : '--:--:--';

    String statusLabel = 'BELUM MASUK';
    Color statusBg = AppColors.canvas;
    Color statusFg = AppColors.textSecondary;

    if (session != null) {
      if (session.status == 'PRESENT') {
        statusLabel = 'PRESENT';
        statusBg = const Color(0xFFD1FAE5);
        statusFg = const Color(0xFF065F46);
      } else if (session.status == 'LATE') {
        statusLabel = 'LATE';
        statusBg = const Color(0xFFFEF3C7);
        statusFg = const Color(0xFF92400E);
      } else if (session.status == 'ABSENT') {
        statusLabel = 'ABSENT';
        statusBg = const Color(0xFFFEE2E2);
        statusFg = const Color(0xFF991B1B);
      }
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Sesi Hari Ini',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-Col Grid: CLOCK-IN & CLOCK-OUT
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLOCK-IN',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inTimeStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isClockedIn
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isClockedIn ? 'Tercatat' : 'Belum Rekam',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isClockedIn
                              ? AppColors.statusSuccess
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLOCK-OUT',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outTimeStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isClockedOut
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isClockedOut
                            ? 'Selesai'
                            : (isClockedIn ? 'Sesi Berjalan' : '-'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Session Info Alert
          if (provider.hasActiveCheckIn)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber 50
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFB45309), // Amber 700
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anda memiliki sesi check-in aktif. Pastikan melakukan check-out saat jam operasional shift selesai.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Contextual Action Button (Clock-In vs Clock-Out)
  Widget _buildContextualActionButton(AttendanceProvider provider) {
    if (provider.hasActiveCheckIn) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            'Lakukan Check-Out Sekarang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () async {
            final res = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClockOutScreen()),
            );
            if (res == true && mounted) {
              provider.fetchTodayAttendance();
            }
          },
        ),
      );
    }

    if (provider.isCompletedToday) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusSuccess,
            side: const BorderSide(color: AppColors.statusSuccess),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: Text(
            'Presensi Hari Ini Telah Tuntas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: null,
        ),
      );
    }

    // Default: Belum Clock-In
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: Text(
          'Lakukan Clock-In Sekarang',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClockInScreen()),
          );
          if (res == true && mounted) {
            provider.fetchTodayAttendance();
          }
        },
      ),
    );
  }

  /// 10B. EMPTY STATE (NO SHIFT TODAY)
  Widget _buildNoShiftEmptyState(AttendanceProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.event_busy_rounded,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Tidak Ada Jadwal Shift Hari Ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda tidak memiliki penugasan shift aktif untuk hari ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            AppButton.secondary(
              text: 'Segarkan Halaman',
              onPressed: () => provider.fetchTodayAttendance(),
            ),
          ],
        ),
      ),
    );
  }
}
