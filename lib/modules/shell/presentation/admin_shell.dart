import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/shared/app_secure_storage.dart';
import '../../../../core/shared/responsive_builder.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';

/// Shell Navigasi Utama untuk Peran Admin & Owner
/// Mendukung layout responsif (BottomNavigationBar pada Mobile, NavigationRail pada Tablet/Desktop).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);

  Future<void> _handleLogout() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Keluar dari Portal Admin?',
      message: 'Sesi manajerial Anda akan ditutup pada perangkat ini.',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await AppSecureStorage().clearAll();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
    }
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(),
      tablet: _buildWideLayout(isDesktop: false),
      desktop: _buildWideLayout(isDesktop: true),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: _buildAppBar(),
      body: _buildCurrentTab(),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _currentIndex,
        builder: (context, currentIndex, child) {
          return AppBottomNavBar(
            currentIndex: currentIndex,
            onTap: _onTabSelected,
            role: AppNavRole.adminOrOwner,
          );
        },
      ),
    );
  }

  Widget _buildWideLayout({required bool isDesktop}) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, currentIndex, child) {
              return NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: _onTabSelected,
                extended: isDesktop,
                minExtendedWidth: 220,
                backgroundColor: AppColors.surface,
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                ),
                selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelTextStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Beranda'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt_rounded),
                    label: Text('Karyawan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.schedule_outlined),
                    selectedIcon: Icon(Icons.schedule_rounded),
                    label: Text('Shift'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.fact_check_outlined),
                    selectedIcon: Icon(Icons.fact_check_rounded),
                    label: Text('Approval'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.payments_outlined),
                    selectedIcon: Icon(Icons.payments_rounded),
                    label: Text('Payroll'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.admin_panel_settings_outlined),
                    selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                    label: Text('Akun/Audit'),
                  ),
                ],
              );
            },
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sixbox HRIS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Selector<AuthProvider, User?>(
                selector: (_, p) => p.user,
                builder: (context, user, _) {
                  return Text(
                    user?.email ?? 'email tidak tersedia',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  Widget _buildCurrentTab() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndex,
      builder: (_, currentIndex, _) {
        switch (currentIndex) {
          case 0:
            return const DashboardScreen(showAppBar: false);
          case 1:
            return _buildEmployeeManagementTab();
          case 2:
            return _buildShiftManagementTab();
          case 3:
            return _buildApprovalTab();
          case 4:
            return _buildPayrollTab();
          case 5:
            return _buildAuditTab();
          default:
            return const DashboardScreen(showAppBar: false);
        }
      },
    );
  }

  Widget _buildEmployeeManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppCard(
                  title: 'Total Karyawan',
                  trailing: const AppBadge.present(label: 'Aktif'),
                  child: Text(
                    '24 Orang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: AppCard(
                  title: 'Departemen',
                  trailing: const AppBadge.active(label: '4 Divisi'),
                  child: Text(
                    '4 Divisi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          AppButton.primary(
            text: 'Tambah Karyawan Baru',
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Form tambah karyawan siap diintegrasikan'),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space20),
          Text(
            'Daftar Karyawan Terbaru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.brand100,
                    child: Text(
                      'BS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'Budi Santoso',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Software Engineer • IT Department',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.present(),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.brand100,
                    child: Text(
                      'SA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'Siti Aminah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'HR Specialist • Human Resources',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.present(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Master Jadwal Shift',
            trailing: const AppBadge.active(label: '3 Shift'),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'Shift Pagi (General)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '08:00 - 16:00 WIB • Toleransi 15 Menit',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: const AppBadge.active(),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.wb_cloudy_outlined,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'Shift Siang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '13:00 - 21:00 WIB • Toleransi 15 Menit',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: const AppBadge.active(),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.nightlight_round,
                    color: Colors.purple,
                  ),
                  title: Text(
                    'Shift Malam',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '21:00 - 05:00 WIB • Toleransi 15 Menit',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: const AppBadge.active(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          AppButton.secondary(
            text: 'Atur & Plot Penugasan Roster Shift',
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plotting roster shift siap diintegrasikan'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Pusat Persetujuan (Approval Center)',
            trailing: const AppBadge.pending(label: '2 Menunggu'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi permohonan cuti, lembur, dan koreksi presensi karyawan.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Permohonan Masuk',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.beach_access_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Budi Santoso — Cuti Tahunan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Tanggal 25 Nov 2026 (1 Hari) • Keperluan Keluarga',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.pending(),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.more_time_rounded,
                    color: AppColors.statusWarning,
                  ),
                  title: Text(
                    'Ahmad Fauzi — Lembur 3 Jam',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '21 Nov 2026 • Maintenance Server Operasional',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.pending(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Periode Penggajian Berjalan',
            trailing: const AppBadge.pending(label: 'Status: DRAFT'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode November 2026 (01 Nov - 30 Nov)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '24 Karyawan siap dihitung gajinya berdasarkan kalkulasi absensi dan kasbon.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                AppButton.primary(
                  text: 'Kalkulasi & Kunci Periode Payroll',
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kalkulasi payroll siap diintegrasikan'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Audit Trail & Rekam Mutasi Data',
            trailing: const AppBadge.active(label: 'Forensik'),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.login_rounded,
                    color: AppColors.statusSuccess,
                  ),
                  title: Text(
                    'LOGIN_SUCCESS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Actor: budi.santoso@sixbox.com • 22 Nov 2026, 08:30 WIB',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'LEAVE_REQUEST_SUBMIT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Actor: budi.santoso@sixbox.com • Modul leave_requests',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          AppButton.destructive(
            text: 'Keluar dari Portal Admin',
            icon: const Icon(Icons.logout_rounded, size: 18),
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }
}
