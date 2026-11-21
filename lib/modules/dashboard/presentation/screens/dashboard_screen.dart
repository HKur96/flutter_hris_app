import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/components/components.dart';
import '../../../../core/shared/app_secure_storage.dart';

/// Screen Dashboard Utama (Employee / Admin)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeNavIndex = 0;
  String _currentUserDisplay = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AppSecureStorage().currentUser;
    if (user != null && mounted) {
      setState(() {
        _currentUserDisplay = user.email;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await AppDialog.showConfirmation(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Sesi login akan dihapus dari penyimpanan perangkat ini.',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (shouldLogout == true && mounted) {
      await AppSecureStorage().clearAll();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KaryaHR Mobile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _currentUserDisplay,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar Sesi',
            icon: const Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.statusDanger,
            ),
            onPressed: _handleLogout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Selamat Datang
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.brand200),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Presensi dan operasional kerja siap digunakan.',
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
              ),
              const SizedBox(height: AppSpacing.space16),

              // Status Presensi Hari Ini
              AppCard(
                title: 'Status Presensi Hari Ini',
                trailing: const AppBadge.present(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadwal Shift',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Pagi (08:00 - 16:00 WIB)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
                          'Jam Masuk (Check-in)',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '07:55 WIB (Tepat Waktu)',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Ringkasan Pengajuan Terakhir
              Text(
                'Pengajuan Terakhir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              AppLeaveListItem(
                title: 'Cuti Tahunan (2 Hari)',
                dateRange: '24 Feb 2025 - 25 Feb 2025',
                note: 'Urusan Keluarga',
                submitDate: '20 Feb 2025',
                statusType: AppBadgeType.pending,
                statusLabel: 'PENDING',
                onTap: () {},
              ),
              AppLeaveListItem(
                title: 'Izin Sakit (1 Hari)',
                dateRange: '10 Feb 2025',
                note: 'Surat Dokter Terlampir',
                submitDate: '10 Feb 2025',
                approvedBy: 'Admin HR',
                statusType: AppBadgeType.approved,
                statusLabel: 'APPROVED',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _activeNavIndex,
        role: AppNavRole.employee,
        onTap: (index) {
          setState(() {
            _activeNavIndex = index;
          });
        },
      ),
    );
  }
}
