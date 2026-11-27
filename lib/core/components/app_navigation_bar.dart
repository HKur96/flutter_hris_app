import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

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
/// - OWNER/ADMIN: 5 tab operasional (Karyawan, Shift, Approval, Payroll, Akun/Audit, Profil)
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final User? currentUser;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = currentUser?.navItems ?? [];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final isSelected = currentIndex == index;
              final item = navItems[index];

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
                          fontSize: currentUser?.role == Role.employee
                              ? 10.5
                              : 9.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
