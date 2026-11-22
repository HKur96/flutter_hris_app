import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/app_text_field.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/core/shared/responsive_builder.dart';
import 'package:flutter_hris_app/core/theme/app_radius.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/widgets/exception_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';

/// Layar 02: Login Screen
/// Sesuai UI Stitch tahap_2_revisi dengan dukungan ResponsiveBuilder
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthProvider _authProvider = context.read<AuthProvider>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _authProvider.login(_emailController.text, _passwordController.text).then((
      user,
    ) {
      if (user == null || !mounted) return;

      if (user.role == Role.admin || user.role == Role.owner) {
        Navigator.of(context).pushReplacementNamed('/admin/shell');
      } else {
        Navigator.of(context).pushReplacementNamed('/employee/shell');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildHeader(),
                    const SizedBox(height: 20),
                    ..._buildFormFields(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildHeader(),
                    const SizedBox(height: 24),
                    ..._buildFormFields(),
                    const SizedBox(height: 24),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Kolom Kiri: Branding & Informasi Enterprise
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: AppColors.brand50,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.xl),
                            bottomLeft: Radius.circular(AppRadius.xl),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.medium,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'KHR',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'KaryaHR Cloud',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sistem Informasi Manajemen Sumber Daya Manusia terintegrasi presensi GPS, payroll, dan persetujuan mandiri.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildFeatureBullet(
                              icon: Icons.location_on_outlined,
                              title: 'Presensi GPS & Shift Kerja',
                              desc: 'Pencatatan kehadiran presisi dengan toleransi keterlambatan.',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureBullet(
                              icon: Icons.approval_outlined,
                              title: 'Persetujuan Terpusat',
                              desc: 'Alur persetujuan cuti, lembur, dan kasbon secara real-time.',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureBullet(
                              icon: Icons.receipt_long_outlined,
                              title: 'Slip Gaji Digital',
                              desc: 'Penerbitan slip gaji transparan dengan rincian tunjangan.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Garis Pemisah
                    Container(width: 1, height: 460, color: AppColors.border),
                    // Kolom Kanan: Formulir Login
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ..._buildHeader(),
                            const SizedBox(height: 24),
                            ..._buildFormFields(),
                            const SizedBox(height: 24),
                            _buildActionButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.brand200),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeader() {
    return [
      const SizedBox(height: 8),
      Text(
        'Masuk ke Akun',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Masukkan email terdaftar dan kata sandi Anda.',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
      ),
    ];
  }

  List<Widget> _buildFormFields() {
    return [
      // Field Email
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Email Akun ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: AppColors.statusDanger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: _emailController,
            hintText: 'Masukkan email',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Field Kata Sandi
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Kata Sandi ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: AppColors.statusDanger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<bool>(
            valueListenable: _obscurePassword,
            builder: (context, obscure, child) {
              return AppTextField(
                controller: _passwordController,
                hintText: 'Masukkan kata sandi',
                obscureText: obscure,
                suffixIcon: GestureDetector(
                  onTap: () {
                    _obscurePassword.value = !_obscurePassword.value;
                  },
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
              );
            },
          ),
        ],
      ),
      Selector<AuthProvider, String?>(
        selector: (_, p) => p.errorMessage,
        builder: (_, errorMessage, _) {
          if (errorMessage == null) {
            return const SizedBox.shrink();
          }

          return ExceptionContainer(errorMessage: errorMessage);
        },
      ),
      const SizedBox(height: 14),

      // Informasi Akses (Sesuai Batasan Scope API)
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Informasi Akses: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Hubungi Administrator atau Owner '
                          'jika Anda lupa kata sandi akun kerja.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionButton() {
    return Selector<AuthProvider, bool>(
      selector: (_, provider) => provider.isLoadingLogin,
      builder: (context, isLoading, child) {
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.75,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Memproses Autentikasi...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Masuk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
