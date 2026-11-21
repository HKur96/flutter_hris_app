import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum AppNavRole {
  employee,
  adminOrOwner,
}

class AppNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const AppNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

/// Modular Bottom Navigation Bar sesuai Tahap 1 Design Foundation.
/// Disesuaikan secara kaku berdasarkan Role API:
/// - EMPLOYEE: 4 tab fungsional (Presensi, Cuti & Izin, Slip Gaji, Profil)
/// - OWNER/ADMIN: 5 tab operasional (Karyawan, Shift, Approval, Payroll, Akun/Audit)
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppNavRole role;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = AppNavRole.employee,
  });

  static const List<AppNavItem> employeeItems = [
    AppNavItem(
      label: 'Presensi',
      activeIcon: Icons.access_time_filled_rounded,
      inactiveIcon: Icons.access_time_rounded,
    ),
    AppNavItem(
      label: 'Cuti & Izin',
      activeIcon: Icons.event_available_rounded,
      inactiveIcon: Icons.event_available_outlined,
    ),
    AppNavItem(
      label: 'Slip Gaji',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
    AppNavItem(
      label: 'Profil',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  static const List<AppNavItem> adminItems = [
    AppNavItem(
      label: 'Karyawan',
      activeIcon: Icons.people_alt_rounded,
      inactiveIcon: Icons.people_alt_outlined,
    ),
    AppNavItem(
      label: 'Shift',
      activeIcon: Icons.schedule_rounded,
      inactiveIcon: Icons.schedule_outlined,
    ),
    AppNavItem(
      label: 'Approval',
      activeIcon: Icons.fact_check_rounded,
      inactiveIcon: Icons.fact_check_outlined,
    ),
    AppNavItem(
      label: 'Payroll',
      activeIcon: Icons.payments_rounded,
      inactiveIcon: Icons.payments_outlined,
    ),
    AppNavItem(
      label: 'Akun/Audit',
      activeIcon: Icons.admin_panel_settings_rounded,
      inactiveIcon: Icons.admin_panel_settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = role == AppNavRole.employee ? employeeItems : adminItems;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: AppColors.brand50,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.inactiveIcon,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: role == AppNavRole.employee ? 10.5 : 9.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
