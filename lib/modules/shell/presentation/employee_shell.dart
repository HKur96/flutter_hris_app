import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/shared/app_secure_storage.dart';
import '../../../../core/shared/responsive_builder.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import 'widgets/profile_view.dart';

/// Shell Navigasi Utama untuk Peran Karyawan (Employee)
/// Mendukung layout responsif (BottomNavigationBar pada Mobile, NavigationRail pada Tablet/Desktop).
class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;
  String _userEmail = 'Karyawan';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await AppSecureStorage().currentUser;
    if (user != null && mounted) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Sesi login akan dihapus dari penyimpanan perangkat ini.',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await AppSecureStorage().clearAll();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppConstants.kRouteLogin, (route) => false);
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildWideLayout(isDesktop: false),
        desktop: _buildWideLayout(isDesktop: true),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      // appBar: _buildAppBar(),
      body: _buildCurrentTab(),
      bottomNavigationBar: Selector<AuthProvider, User?>(
        selector: (_, p) => p.user,
        builder: (context, user, _) {
          return AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            currentUser: user,
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
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            extended: isDesktop,
            minExtendedWidth: 200,
            backgroundColor: AppColors.surface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
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
                icon: Icon(Icons.access_time_rounded),
                selectedIcon: Icon(Icons.access_time_filled_rounded),
                label: Text('Presensi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available_rounded),
                label: Text('Cuti & Izin'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: Text('Slip Gaji'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: Text('Profil'),
              ),
            ],
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            alignment: Alignment.center,
            child: Text(
              'KHR',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KaryaHR Mobile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _userEmail,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.statusDanger,
            ),
            onPressed: _handleLogout,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return _buildLeaveTab();
      case 2:
        return _buildPayslipTab();
      case 3:
        return _buildProfileTab();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Saldo & Kuota Cuti',
            trailing: const AppBadge.active(label: 'Tahun 2026'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '12 Hari',
                  'Hak Cuti Tahunan',
                  AppColors.primary,
                ),
                Container(height: 36, width: 1, color: AppColors.border),
                _buildStatItem(
                  '3 Hari',
                  'Sudah Diambil',
                  AppColors.statusWarning,
                ),
                Container(height: 36, width: 1, color: AppColors.border),
                _buildStatItem('9 Hari', 'Sisa Saldo', AppColors.statusSuccess),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          AppButton.primary(
            text: 'Ajukan Permohonan Cuti Baru',
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Form pengajuan cuti siap diintegrasikan'),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space20),
          Text(
            'Riwayat Pengajuan Terakhir',
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
                    'Cuti Tahunan (2 Hari)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '10 Nov 2026 - 11 Nov 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.approved(),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.statusWarning,
                  ),
                  title: Text(
                    'Izin Sakit (1 Hari)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '24 Okt 2026 • Disertai surat dokter',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const AppBadge.approved(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: 'Slip Gaji Digital',
            trailing: const AppBadge.finalized(label: 'Periode Terkunci'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode Oktober 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Slip gaji resmi diterbitkan oleh Bagian Keuangan.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                AppButton.secondary(
                  text: 'Lihat Rincian & Unduh PDF',
                  icon: const Icon(Icons.download_rounded, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rincian slip gaji siap diintegrasikan'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Arsip Slip Gaji',
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
                  title: Text(
                    'Slip Gaji September 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Dibayarkan 28 Sep 2026',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Slip Gaji Agustus 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Dibayarkan 28 Agu 2026',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
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

  Widget _buildProfileTab() {
    return const ProfileView();
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
