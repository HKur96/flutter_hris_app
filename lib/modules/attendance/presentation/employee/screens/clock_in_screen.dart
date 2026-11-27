import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/widgets/location_radius_card.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 02, 09A, & 09B — Konfirmasi Clock-In & Keandalan GPS
/// Sesuai spesifikasi Stitch Stage 6: Attendance (KaryaHR Mobile).
class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  final TextEditingController _notesController = TextEditingController();
  final DateTime _deviceTime = DateTime.now();

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

  Future<void> _handleConfirmClockIn() async {
    final provider = context.read<AttendanceProvider>();
    final notes = _notesController.text.trim();

    final success = await provider.executeCheckIn(
      notes: notes.isNotEmpty ? notes : null,
      rejectMock: true,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.show(
        context,
        message: 'Check-In berhasil tercatat!',
        type: SnackBarType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      final errorMsg =
          provider.clockError ?? 'Gagal melakukan check-in. Silakan coba lagi.';
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
              'Konfirmasi Clock-In',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pencatatan Kehadiran Mandiri',
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
          // 09A. STATE: Izin Lokasi Ditolak
          if (provider.isLocationDenied) {
            return _buildPermissionDeniedView(provider);
          }

          // 09B. STATE: Mock GPS Terdeteksi (SafeDevice Rejection)
          if (provider.isMockDetected) {
            return _buildMockGpsDetectedView(provider);
          }

          // 02. NORMAL STATE: Form Konfirmasi Clock-In
          return _buildClockInForm(provider);
        },
      ),
    );
  }

  /// 02. Form Utama Konfirmasi Clock-In
  Widget _buildClockInForm(AttendanceProvider provider) {
    final user = context.watch<AuthProvider>().user;
    final position = provider.currentPosition;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profil & Waktu Perangkat
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
                      'Karyawan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      user?.name ?? 'Karyawan',
                      style: GoogleFonts.plusJakartaSans(
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
                      'Waktu Perangkat',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${DateFormatter.dateTimeToString(_deviceTime, 'dd MMM yyyy, HH:mm')} WIB',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
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
                      'Shift Kerja',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Shift Pagi (08:00 - 17:00)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
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

          // GPS Koordinat Numerik (Strict No Map)
          LocationRadiusCard(
            title: 'Koordinat Clock-In',
            latitude: position?.latitude,
            longitude: position?.longitude,
            isLoading: provider.isFetchingLocation,
            onRefreshLocation: () =>
                provider.determineLocation(forceRequest: true),
          ),
          const SizedBox(height: AppSpacing.space16),

          // Notes Area (Maksimum 255 Karakter Sesuai Payload)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catatan Presensi',
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
                maxLength: 255,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Masuk tepat waktu di gerbang utama...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.space12),
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
              Text(
                'Maksimum 255 karakter sesuai spesifikasi payload.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space24),

          // Submit & Cancel Buttons
          AppButton.primary(
            text: 'Konfirmasi Clock-In',
            isLoading: provider.isSubmittingClock,
            onPressed: provider.isSubmittingClock
                ? null
                : () => _handleConfirmClockIn(),
          ),
          const SizedBox(height: AppSpacing.space8),
          AppButton.secondary(
            text: 'Batal',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 09A. Izin Lokasi Ditolak View
  Widget _buildPermissionDeniedView(AttendanceProvider provider) {
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
                color: Color(0xFFFEE2E2), // Red 100
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.location_disabled_rounded,
                size: 32,
                color: AppColors.statusDanger,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Izin Lokasi Perangkat Ditolak',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aplikasi memerlukan koordinat GPS perangkat untuk validasi kehadiran saat check-in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah Penyelesaian:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow('1.', 'Buka Pengaturan ponsel Anda.'),
                  const SizedBox(height: 4),
                  _buildStepRow('2.', 'Pilih menu Aplikasi > KaryaHR.'),
                  const SizedBox(height: 4),
                  _buildStepRow(
                    '3.',
                    'Aktifkan Izin Lokasi menjadi "Izinkan Saat Aplikasi Digunakan".',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            AppButton.primary(
              text: 'Buka Pengaturan Izin',
              onPressed: () => provider.openLocationSettings(),
            ),
            const SizedBox(height: AppSpacing.space8),
            AppButton.secondary(
              text: 'Coba Dapatkan Lokasi Lagi',
              onPressed: () => provider.determineLocation(forceRequest: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Text(
            num,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 09B. Mock GPS Terdeteksi View
  Widget _buildMockGpsDetectedView(AttendanceProvider provider) {
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
                color: Color(0xFFFEF3C7), // Amber 100
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: AppColors.statusWarning,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Lokasi Palsu (Mock GPS) Terdeteksi',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sistem keamanan SafeDevice mendeteksi aplikasi fake GPS / mock location aktif pada smartphone Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber 50
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 15,
                        color: Color(0xFFB45309), // Amber 700
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kebijakan Keamanan Perusahaan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E), // Amber 800
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Permintaan check-in ditolak secara otomatis. Harap nonaktifkan mode pengembang atau aplikasi pemalsu lokasi.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            AppButton.primary(
              text: 'Pindai Ulang Perangkat',
              onPressed: () {
                provider.resetMockDetection();
                provider.determineLocation(forceRequest: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
