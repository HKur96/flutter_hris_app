import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/app_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/config/enum.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

/// Alias untuk tampilan profil lintas peran (Owner, Admin, Employee)
typedef ProfileView = AdminProfileView;

/// Tampilan Tab Profil Responsif & Role-Aware (Owner, Admin, Employee)
/// Sesuai 100% dengan spesifikasi desain visual Stitch:
/// - Screen ID: 58b96813084848c1860c65f97c76e904 (Tahap Profil — Profile & Account Management)
/// - Viewport 1: Role OWNER (Akses Ubah Nama Toko via Modal + Ubah Password + Logout)
/// - Viewport 2: Role EMPLOYEE Full Data (NIK, Jabatan, Departemen, Tempat Bekerja Read-Only)
/// - Viewport 3: Role EMPLOYEE Graceful Degradation (Banner akun belum tertaut NIK)
/// - Viewport 4: Bottom Sheet Ubah Nama Toko (PUT /api/v1/auth/store)
/// - Viewport 5: Bottom Sheet Ubah Kata Sandi (POST /api/v1/auth/change-password)
class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  // Palet Warna Resmi Stitch Design System
  static const Color _cSurface = Color(0xFFF8F9FF);
  static const Color _cCardBg = Colors.white;
  static const Color _cPrimaryContainer = Color(0xFF15803D);
  static const Color _cPrimaryFixed = Color(0xFF95F8A7);
  static const Color _cOnPrimaryFixed = Color(0xFF00210A);
  static const Color _cSecondary = Color(0xFF565E74);
  static const Color _cSecondaryContainer = Color(0xFFDAE2FD);
  static const Color _cOnSecondaryFixed = Color(0xFF131B2E);
  static const Color _cSurfaceContainer = Color(0xFFE5EEFF);
  static const Color _cSurfaceContainerLow = Color(0xFFEFF4FF);
  static const Color _cOnSurface = Color(0xFF0B1C30);
  static const Color _cOnSurfaceVariant = Color(0xFF3F493F);
  static const Color _cOutline = Color(0xFF6F7A6E);
  static const Color _cOutlineVariant = Color(0xFFBECABC);
  static const Color _cErrorContainer = Color(0xFFFFDAD6);
  static const Color _cOnErrorContainer = Color(0xFF93000A);

  Future<void> _handleSaveStoreName(String newStoreName) async {
    final trimmed = newStoreName.trim();
    if (trimmed.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateStoreName(trimmed);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Nama toko berhasil diperbarui menjadi "$trimmed"'
              : (authProvider.errorMessage ?? 'Gagal memperbarui nama toko.'),
          style: GoogleFonts.inter(fontSize: 12.5),
        ),
        backgroundColor: success ? _cPrimaryContainer : const Color(0xFFBA1A1A),
      ),
    );
  }

  Future<void> _handleChangePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Kata sandi berhasil diperbarui'
              : (authProvider.errorMessage ?? 'Gagal memperbarui kata sandi'),
          style: GoogleFonts.inter(fontSize: 12.5),
        ),
        backgroundColor: success ? _cPrimaryContainer : const Color(0xFFBA1A1A),
      ),
    );
  }

  /// Dialog Konfirmasi Logout Destruktif mirip _showSoftDeleteDialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _cSurfaceContainer),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keluar dari Akun?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _cOnSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Sesi akun ',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: _cOnSurfaceVariant,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: user?.email ?? 'Anda',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _cOnSurface,
                    ),
                  ),
                  const TextSpan(
                    text: ' akan ditutup pada perangkat ini. Anda harus masuk kembali untuk mengelola sistem.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Catatan Keamanan & Integritas Data
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cSurfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cSurfaceContainer),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 16,
                    color: _cPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seluruh data toko, profil karyawan, jadwal shift, dan laporan payroll tetap tersimpan aman di database cloud.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _cOnSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cOnSurface,
                      side: const BorderSide(color: _cSurfaceContainer),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      Navigator.of(dialogCtx).pop();
                      await context.read<AuthProvider>().logout();
                      navigator.pushNamedAndRemoveUntil(
                        AppConstants.kRouteLogin,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Ya, Keluar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Viewport 4: Bottom Sheet Ubah Nama Toko (PUT /api/v1/auth/store)
  void _showUpdateStoreBottomSheet(BuildContext context) {
    final currentStore = context.read<AuthProvider>().user?.storeName ?? '';
    final sheetController = TextEditingController(text: currentStore);
    final sheetFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: sheetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle (w-8 h-1 bg-outline-variant)
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _cOutlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ubah Nama Toko',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _cOnSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _cPrimaryFixed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PUT /auth/store',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _cOnPrimaryFixed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Nama toko akan diperbarui pada slip gaji & laporan.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: _cOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _cOutline,
                      ),
                      onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: _cSurfaceContainer,
                ),

                // Field 1: Read-only Nama Toko Saat Ini
                Text(
                  'Nama Toko Saat Ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _cOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _cSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cSurfaceContainer),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentStore.isNotEmpty ? currentStore : '-',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _cOnSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: _cOutline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Field 2: Nama Toko Baru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Nama Toko Baru ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _cOnSurface,
                        ),
                        children: const [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Color(0xFFBA1A1A)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${sheetController.text.length}/60',
                      style: GoogleFonts.inter(fontSize: 11, color: _cOutline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: sheetController,
                  maxLength: 60,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama entitas usaha',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: _cOutline,
                    ),
                    prefixIcon: const Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: _cPrimaryContainer,
                    ),
                    suffixIcon: sheetController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: _cOutline,
                            ),
                            onPressed: () {
                              sheetController.clear();
                              setSheetState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _cSurfaceContainer),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _cPrimaryContainer,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama toko tidak boleh kosong';
                    }
                    if (val.trim().length < 3) {
                      return 'Nama toko minimal 3 karakter';
                    }
                    return null;
                  },
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maksimal 60 karakter.',
                  style: GoogleFonts.inter(fontSize: 11, color: _cOutline),
                ),
                const SizedBox(height: 20),

                // Docked Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cSurfaceContainer),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _cOnSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cPrimaryContainer,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (!sheetFormKey.currentState!.validate()) {
                              return;
                            }
                            final newName = sheetController.text.trim();
                            Navigator.of(bottomSheetCtx).pop();
                            await _handleSaveStoreName(newName);
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Viewport 5: Bottom Sheet Ubah Kata Sandi (POST /api/v1/auth/change-password)
  void _showChangePasswordBottomSheet(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: passwordFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _cOutlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Ubah Kata Sandi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _cOnSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: _cOutline,
                        ),
                        onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                      ),
                    ],
                  ),

                  // 1. Kata Sandi Saat Ini
                  AppTextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    isPassword: true,
                    isRequired: true,
                    label: 'Kata Sandi Saat Ini',
                    hintText: 'Masukkan Kata Sandi Saat Ini',
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi saat ini wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Kata Sandi Baru
                  AppTextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    isPassword: true,
                    isRequired: true,
                    label: 'Kata Sandi Baru',
                    hintText: 'Masukkan Kata Sandi Baru',
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi baru wajib diisi';
                      }
                      if (val.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      return null;
                    },
                    onChanged: (_) => setSheetState(() {}),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 14),

                  // 3. Konfirmasi Kata Sandi Baru
                  AppTextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    label: 'Konfirmasi Kata Sandi Baru',
                    hintText: 'Ulangi kata sandi baru',
                    isPassword: true,
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Konfirmasi kata sandi wajib diisi';
                      }
                      if (val != newPasswordController.text) {
                        return 'Konfirmasi kata sandi tidak cocok';
                      }
                      return null;
                    },
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _cSurfaceContainer),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _cOnSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cPrimaryContainer,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!passwordFormKey.currentState!
                                        .validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSubmitting = true);
                                    final oldPass = oldPasswordController.text
                                        .trim();
                                    final newPass = newPasswordController.text
                                        .trim();
                                    Navigator.of(bottomSheetCtx).pop();
                                    await _handleChangePassword(
                                      oldPassword: oldPass,
                                      newPassword: newPass,
                                    );
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan Kata Sandi',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final role = user?.role ?? Role.employee;
    final isOwner = role == Role.owner;
    final isAdmin = role == Role.admin;
    final isEmployee = role == Role.employee;

    // Hitung inisial avatar (1-2 karakter)
    String initial = 'A';
    if (user != null && user.name.isNotEmpty) {
      final parts = user.name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initial = parts[0][0].toUpperCase();
      }
    } else if (user != null &&
        user.storeName.isNotEmpty &&
        user.storeName != '-') {
      initial = user.storeName[0].toUpperCase();
    }

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (user?.storeName.isNotEmpty == true && user?.storeName != '-'
              ? user!.storeName
              : 'Pengguna KaryaHR');

    return Container(
      color: _cSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Identity Card (Sesuai Stitch)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cSurfaceContainer),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080B1C30),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isOwner || isAdmin
                          ? _cPrimaryFixed
                          : (user?.nik != null && user!.nik!.isNotEmpty ||
                                    user?.employeeId.isNotEmpty == true &&
                                        user?.employeeId != '-'
                                ? _cSecondaryContainer
                                : _cSurfaceContainer),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isOwner || isAdmin
                            ? _cOnPrimaryFixed
                            : (user?.nik != null && user!.nik!.isNotEmpty ||
                                      user?.employeeId.isNotEmpty == true &&
                                          user?.employeeId != '-'
                                  ? _cOnSecondaryFixed
                                  : _cOnSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _cOnSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _cOnSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOwner || isAdmin
                                    ? _cPrimaryContainer
                                    : _cSurfaceContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isOwner
                                    ? 'OWNER'
                                    : (isAdmin ? 'ADMIN' : 'KARYAWAN'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: isOwner || isAdmin
                                      ? Colors.white
                                      : _cSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Section: Informasi Akun (All Roles)
            _buildSectionHeader('INFORMASI AKUN'),
            Container(
              decoration: BoxDecoration(
                color: _cCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cSurfaceContainer),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080B1C30),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Email Terdaftar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Terdaftar',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _cOnSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '-',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _cOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: _cSurfaceContainer,
                  ),

                  // Row 2: Hak Akses Sistem
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hak Akses Sistem',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _cOnSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOwner
                                  ? 'Owner / Pemilik Usaha'
                                  : (isAdmin
                                        ? 'Administrator Sistem'
                                        : 'Staf Karyawan'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _cOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Section Khusus EMPLOYEE: Informasi Kepegawaian (Viewport 2 & 3)
            if (isEmployee) ...[
              if (user?.nik != null && user!.nik!.isNotEmpty ||
                  user?.employeeId.isNotEmpty == true &&
                      user?.employeeId != '-') ...[
                // Viewport 2: Full Data Available
                _buildSectionHeader('INFORMASI KEPEGAWAIAN'),
                Container(
                  decoration: BoxDecoration(
                    color: _cCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cSurfaceContainer),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080B1C30),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // NIK
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nomor Induk Karyawan (NIK)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _cOnSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.nik ?? '-',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _cOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: _cSurfaceContainer,
                      ),

                      // Jabatan / Posisi
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jabatan / Posisi',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _cOnSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.position ?? 'Staff Karyawan',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _cOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: _cSurfaceContainer,
                      ),

                      // Departemen
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Departemen',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _cOnSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.department ?? 'Operasional',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _cOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Viewport 3: Graceful Degradation (Belum tertaut NIK)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cOutlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF005B8C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akun Belum Tertaut NIK',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _cOnSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Data detail kepegawaian (NIK & Jabatan) belum terhubung dengan akun login ini. Hubungi pemilik usaha atau HR untuk melengkapi profil staf.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: _cOnSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tempat Bekerja (Strict Read-Only Enforcement untuk Employee)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('TEMPAT BEKERJA'),
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: _cOutline,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Hanya Baca',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _cOutline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cSurfaceContainer),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080B1C30),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Toko / Badan Usaha',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _cOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.storeName.isNotEmpty == true &&
                                    user?.storeName != '-'
                                ? user!.storeName
                                : 'KaryaHR Store',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _cOnSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: _cOutline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Section Khusus OWNER & ADMIN: Informasi Perusahaan (Viewport 1 & 4)
            if (isOwner || isAdmin) ...[
              _buildSectionHeader('INFORMASI PERUSAHAAN'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cSurfaceContainer),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080B1C30),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Toko / Perusahaan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _cOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.storeName.isNotEmpty == true &&
                                    user?.storeName != '-'
                                ? user!.storeName
                                : 'Nama Toko Belum Diatur',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _cOnSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Terhubung ke data operasional & slip gaji aktif',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _cOutline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _cPrimaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showUpdateStoreBottomSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ubah',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 5. Section: Keamanan & Autentikasi (All Roles)
            _buildSectionHeader(
              isEmployee ? 'KEAMANAN AKUN' : 'KEAMANAN & AUTENTIKASI',
            ),
            Container(
              decoration: BoxDecoration(
                color: _cCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cSurfaceContainer),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080B1C30),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showChangePasswordBottomSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ubah Kata Sandi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _cOnSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _cOutline,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. Tombol Logout Destruktif (All Roles)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cErrorContainer,
                  foregroundColor: _cOnErrorContainer,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showLogoutConfirmationDialog(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Keluar dari Aplikasi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _cOnErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: _cOnSurfaceVariant,
        ),
      ),
    );
  }
}
