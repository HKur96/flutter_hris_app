import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/widgets/location_radius_card.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 03 — Konfirmasi Clock-Out
/// Sesuai spesifikasi Stitch Stage 6: Attendance (KaryaHR Mobile).
class ClockOutScreen extends StatefulWidget {
  const ClockOutScreen({super.key});

  @override
  State<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends State<ClockOutScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceProvider>();
      if (provider.currentPosition == null) {
        provider.determineLocation(forceRequest: true);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _calculateEstimatedDuration(DateTime? checkIn) {
    if (checkIn == null) return '-';
    final diff = DateTime.now().difference(checkIn);
    if (diff.isNegative) return '0 Menit';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '$hours Jam $minutes Menit';
    }
    return '$minutes Menit';
  }

  Future<void> _handleConfirmClockOut() async {
    final provider = context.read<AttendanceProvider>();
    final notes = _notesController.text.trim();

    final success = await provider.executeCheckOut(
      notes: notes.isNotEmpty ? notes : null,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.show(
        context,
        message: 'Clock-Out berhasil! Sesi kerja hari ini selesai.',
        type: SnackBarType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      final errorMsg =
          provider.clockError ??
          'Gagal melakukan clock-out. Silakan coba lagi.';
      AppSnackBar.show(context, message: errorMsg, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi Clock-Out',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Akhiri Sesi Kerja Harian',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          final session = provider.todayAttendance;
          final position = provider.currentPosition;
          final checkInTimeStr = session?.checkIn != null
              ? '${DateFormatter.dateTimeToString(session!.checkIn!, 'HH:mm:ss')} WIB'
              : '--:--:--';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sesi Check-in Aktif & Estimasi Durasi
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jam Check-In',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            checkInTimeStr,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwal Shift',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            session?.shiftName.isNotEmpty == true
                                ? session!.shiftName
                                : 'Shift Pagi (08:00 - 17:00)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Perkiraan Durasi',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _calculateEstimatedDuration(session?.checkIn),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // GPS Koordinat Check-out (Strict Plain Text, No Map)
                LocationRadiusCard(
                  title: 'Koordinat Clock-Out',
                  latitude: position?.latitude,
                  longitude: position?.longitude,
                  isLoading: provider.isFetchingLocation,
                  onRefreshLocation: () =>
                      provider.determineLocation(forceRequest: true),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Notes Optional
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catatan Kepulangan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Opsional',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 255,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Catatan pekerjaan selesai, handover tugas...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        contentPadding: const EdgeInsets.all(
                          AppSpacing.space12,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space24),

                // Submit & Cancel Buttons
                AppButton.primary(
                  text: 'Konfirmasi Clock-Out',
                  isLoading: provider.isSubmittingClock,
                  onPressed: provider.isSubmittingClock
                      ? null
                      : () => _handleConfirmClockOut(),
                ),
                const SizedBox(height: AppSpacing.space8),
                AppButton.secondary(
                  text: 'Batal',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
