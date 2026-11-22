import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/app_text_field.dart';
import 'package:flutter_hris_app/core/helper/validator.dart';
import 'package:flutter_hris_app/core/shared/responsive_builder.dart';
import 'package:flutter_hris_app/core/theme/app_radius.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../provider/auth_provider.dart';

/// Layar 03: Setup OWNER Pertama (Inisialisasi Sistem)
/// Sesuai UI Stitch tahap_2_revisi dengan dukungan ResponsiveBuilder
class InitialOwnerSetupScreen extends StatefulWidget {
  final String? deploymentId;

  const InitialOwnerSetupScreen({super.key, this.deploymentId});

  @override
  State<InitialOwnerSetupScreen> createState() =>
      _InitialOwnerSetupScreenState();
}

class _InitialOwnerSetupScreenState extends State<InitialOwnerSetupScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<bool> _obscureConfirmPassword = ValueNotifier(true);
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _obscurePassword.dispose();
    _obscureConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOwner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi wajib diisi')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok')),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final user = await authProvider.setupOwner(email, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/admin/shell');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Gagal membuat akun OWNER',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildWideLayout(maxWidth: 540),
        desktop: _buildWideLayout(maxWidth: 580),
      ),
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

  Widget _buildWideLayout({required double maxWidth}) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
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

  List<Widget> _buildHeader() {
    return [
      const SizedBox(height: 8),
      Text(
        'Inisialisasi Sistem',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Buat akun OWNER utama untuk mengelola aplikasi. Formulir ini hanya muncul saat belum ada akun terdaftar di sistem.',
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }

  List<Widget> _buildFormFields() {
    return [
      // Field Email OWNER
      AppTextField(
        controller: _emailController,
        label: 'Email Owner',
        hintText: 'Masukkan email owner',
        isRequired: true,
        verticalPadding: 11,
        isDense: true,
        validator: Validators.emailValidator,
      ),
      const SizedBox(height: 14),

      // Field Kata Sandi
      ValueListenableBuilder<bool>(
        valueListenable: _obscurePassword,
        builder: (context, obscure, child) {
          return AppTextField(
            controller: _passwordController,
            label: 'Kata Sandi',
            hintText: 'Masukkan kata sandi',
            isRequired: true,
            isPassword: true,
            verticalPadding: 11,
            isDense: true,
            obscureText: obscure,
            validator: Validators.passwordValidator,
            suffixIcon: GestureDetector(
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                _obscurePassword.value = !_obscurePassword.value;
              },
            ),
          );
        },
      ),
      const SizedBox(height: 14),

      // Field Konfirmasi Kata Sandi
      ValueListenableBuilder<bool>(
        valueListenable: _obscureConfirmPassword,
        builder: (context, obscure, child) {
          return AppTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Kata Sandi',
            hintText: 'Masukkan konfirmasi kata sandi',
            isRequired: true,
            isPassword: true,
            verticalPadding: 11,
            isDense: true,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            validator: (val) =>
                Validators.confirmPasswordValidator(val, _passwordController),
            suffixIcon: GestureDetector(
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
              },
            ),
            onSubmitted: (val) => _handleCreateOwner(),
          );
        },
      ),
      const SizedBox(height: 14),

      // Info Role Mutlak Box
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
            children: const [
              TextSpan(text: 'Akun otomatis ditetapkan dengan role '),
              TextSpan(
                text: 'OWNER',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' yang memiliki otoritas mutlak konfigurasi data HRIS.',
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateOwner,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.75),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Buat Akun OWNER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
