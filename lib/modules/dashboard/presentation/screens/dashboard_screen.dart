import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/config/enum.dart';
import '../widgets/admin_dashboard_view.dart';
import '../widgets/employee_dashboard_view.dart';
import '../widgets/owner_dashboard_view.dart';

/// Screen Dashboard Utama (Role-Based: Owner, Admin HR, Employee)
/// Sesuai implementasi Stitch Mobile Phase 1 — Role-Based Dashboard.
class DashboardScreen extends StatefulWidget {
  final bool showAppBar;

  const DashboardScreen({super.key, this.showAppBar = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, User?>(
      selector: (_, p) => p.user,
      builder: (_, user, _) {
        Widget content;
        switch (user?.role) {
          case Role.owner:
            content = OwnerDashboardView(user: user, onRefresh: () async {});
            break;
          case Role.admin:
            content = AdminDashboardView(user: user, onRefresh: () async {});
            break;
          default:
            content = EmployeeDashboardView(user: user, onRefresh: () async {});
            break;
        }

        final refreshableContent = RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {},
          child: content,
        );

        if (!widget.showAppBar) {
          return refreshableContent;
        }
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sixbox HRIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user?.name ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.border, height: 1),
            ),
          ),
          body: SafeArea(child: refreshableContent),
        );
      },
    );
  }
}
