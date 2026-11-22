import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/core/helper/dio_helper.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/shared/app_secure_storage.dart';

/// Screen Splash awal aplikasi dengan logika pengecekan sesi login pengguna
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthProvider _authProvider = context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentUserSession();
    });
  }

  Future<void> _checkCurrentUserSession() async {
    // Beri sedikit jeda waktu agar transisi layar splash nyaman
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      final deploymentId = await AppSecureStorage().readDeploymentId();

      if (deploymentId == null) {
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(AppConstants.kRouteDeploymentConfig);
        return;
      }

      // Setup dio helper base url
      const baseUrl = String.fromEnvironment(
        'base_url',
        defaultValue: 'https://script.google.com/macros/s/',
      );
      DioHelper.instance.baseUrl = '$baseUrl$deploymentId/exec';

      final user = await _authProvider.getCurrentUser();

      if (!mounted) return;

      if (user == null) {
        // Cek setup-status backend apakah butuh setup owner pertama kali
        final setupStatus = await _authProvider.checkSetupStatus(
          showLoadingDialog: false,
        );
        if (!mounted) return;

        if (setupStatus != null &&
            setupStatus.needsSetup &&
            !setupStatus.hasOwner) {
          Navigator.of(context)
              .pushReplacementNamed(AppConstants.kRouteInitOwnerSetup);
        } else {
          Navigator.of(context).pushReplacementNamed(AppConstants.kRouteLogin);
        }
      } else {
        // Jika currentUser ada, arahkan ke shell sesuai role
        if (user.role == Role.admin || user.role == Role.owner) {
          Navigator.of(context)
              .pushReplacementNamed(AppConstants.kRouteAdminShell);
        } else {
          Navigator.of(context)
              .pushReplacementNamed(AppConstants.kRouteEmployeeShell);
        }
      }
    } catch (_) {
      // Jika terjadi kegagalan baca storage, default aman ke login
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.kRouteLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Brand KHR Sesuai Tahap 1
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.primaryDark, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'KHR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Title
              Text(
                'KaryaHR Mobile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Sistem Manajemen Kehadiran & HRIS',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space32),

              LoadingAnimationWidget.progressiveDots(
                color: AppColors.primary,
                size: MediaQuery.of(context).size.width * 0.2,
              ),
              const SizedBox(height: AppSpacing.space12),

              Selector<AuthProvider, String?>(
                selector: (_, p) => p.loadingMessage,
                builder: (context, message, _) {
                  return Text(
                    message ?? 'Memeriksa status akun...',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
