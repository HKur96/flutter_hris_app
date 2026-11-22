// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hris_app/core/components/app_text_field.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/shared/responsive_builder.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/widgets/exception_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Layar 01: Hubungkan Aplikasi (Deployment Configuration)
/// Sesuai UI Stitch tahap_2_revisi
class DeploymentConfigScreen extends StatefulWidget {
  const DeploymentConfigScreen({super.key});

  @override
  State<DeploymentConfigScreen> createState() => _DeploymentConfigScreenState();
}

class _DeploymentConfigScreenState extends State<DeploymentConfigScreen> {
  late final AuthProvider _authProvider = context.read<AuthProvider>();

  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final TextEditingController _thirdController = TextEditingController();
  final TextEditingController _fourthController = TextEditingController();
  final TextEditingController _fifthController = TextEditingController();
  final TextEditingController _sixthController = TextEditingController();

  final FocusNode _firstFocus = FocusNode();
  final FocusNode _secondFocus = FocusNode();
  final FocusNode _thirdFocus = FocusNode();
  final FocusNode _fourthFocus = FocusNode();
  final FocusNode _fifthFocus = FocusNode();
  final FocusNode _sixthFocus = FocusNode();

  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  void _validateForm() {
    _isFormValid.value =
        _firstController.text.isNotEmpty &&
        _secondController.text.isNotEmpty &&
        _thirdController.text.isNotEmpty &&
        _fourthController.text.isNotEmpty &&
        _fifthController.text.isNotEmpty &&
        _sixthController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _firstController.addListener(_validateForm);
    _secondController.addListener(_validateForm);
    _thirdController.addListener(_validateForm);
    _fourthController.addListener(_validateForm);
    _fifthController.addListener(_validateForm);
    _sixthController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _firstController.removeListener(_validateForm);
    _secondController.removeListener(_validateForm);
    _thirdController.removeListener(_validateForm);
    _fourthController.removeListener(_validateForm);
    _fifthController.removeListener(_validateForm);
    _sixthController.removeListener(_validateForm);

    _firstController.dispose();
    _secondController.dispose();
    _thirdController.dispose();
    _fourthController.dispose();
    _fifthController.dispose();
    _sixthController.dispose();

    _firstFocus.dispose();
    _secondFocus.dispose();
    _thirdFocus.dispose();
    _fourthFocus.dispose();
    _fifthFocus.dispose();
    _sixthFocus.dispose();

    _isFormValid.dispose();
    super.dispose();
  }

  String get _code =>
      _firstController.text +
      _secondController.text +
      _thirdController.text +
      _fourthController.text +
      _fifthController.text +
      _sixthController.text;

  /// Logika auto-focus antar 6 field input:
  /// - Berpindah ke field berikutnya jika karakter terisi
  /// - Kembali ke field sebelumnya jika karakter dihapus
  /// - Mendukung penempelan (paste) kode penuh 6 karakter
  void _onCodeChanged(
    String value,
    int index,
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
    FocusNode? prevFocus,
  ) {
    // 1. Dukungan Paste multi-karakter (misal "ABC123" atau "ABC-123")
    if (value.length >= 3) {
      final clean = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final controllers = [
        _firstController,
        _secondController,
        _thirdController,
        _fourthController,
        _fifthController,
        _sixthController,
      ];
      final focusNodes = [
        _firstFocus,
        _secondFocus,
        _thirdFocus,
        _fourthFocus,
        _fifthFocus,
        _sixthFocus,
      ];

      for (int i = 0; i < controllers.length; i++) {
        if (i < clean.length) {
          controllers[i].text = clean[i];
        }
      }

      if (clean.length >= 6) {
        focusNodes.last.unfocus();
      } else {
        focusNodes[clean.length].requestFocus();
      }
      return;
    }

    // 2. Jika user mengetik huruf baru pada field yang sudah terisi
    if (value.length == 2) {
      final newChar = value.characters.last.toUpperCase();
      controller.text = newChar;
      controller.selection = TextSelection.collapsed(offset: 1);
      nextFocus?.requestFocus();
      return;
    }

    // 3. Karakter terisi (1 karakter): pindah fokus ke field selanjutnya
    if (value.isNotEmpty) {
      controller.text = value.toUpperCase();
      controller.selection = TextSelection.collapsed(offset: 1);
      if (nextFocus != null) {
        nextFocus.requestFocus();
      } else {
        currentFocus.unfocus();
      }
    } else {
      // 4. Karakter dihapus: kembali ke field sebelumnya
      prevFocus?.requestFocus();
    }
  }

  Widget _buildCodeInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    FocusNode? prevFocus,
    required int index,
  }) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (controller.text.isEmpty && prevFocus != null) {
            prevFocus.requestFocus();
          }
        }
      },
      child: AppTextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text,
        verticalPadding: 12,
        inputFormatters: [
          LengthLimitingTextInputFormatter(6),
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        onSubmitted: (v) {
          _handleConnectServer();
        },
        onChanged: (val) => _onCodeChanged(
          val,
          index,
          controller,
          focusNode,
          nextFocus,
          prevFocus,
        ),
      ),
    );
  }

  Future<void> _handleConnectServer() async {
    if (await _authProvider.connectServer(_code) && mounted) {
      final setupStatus = await _authProvider.checkSetupStatus();
      if (!mounted) return;

      if (setupStatus != null &&
          setupStatus.needsSetup &&
          !setupStatus.hasOwner) {
        Navigator.of(context)
            .pushReplacementNamed(AppConstants.kRouteInitOwnerSetup);
      } else {
        Navigator.of(context).pushReplacementNamed(AppConstants.kRouteLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(),
      tablet: _buildWideLayout(maxWidth: 500),
      desktop: _buildWideLayout(maxWidth: 540),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildHeader(),
                    const SizedBox(height: 40),
                    ..._buildField(),
                    _buildErrorMessage(),
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
                    const SizedBox(height: 32),
                    ..._buildField(),
                    _buildErrorMessage(),
                    const SizedBox(height: 32),
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

  Widget _buildActionButton() {
    return Selector<AuthProvider, bool>(
      selector: (context, provider) => provider.isLoadingLogin,
      builder: (context, isLoading, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isFormValid,
          builder: (context, isFormValid, child) {
            return SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isLoading || !isFormValid
                    ? null
                    : _handleConnectServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.7,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hubungkan Server',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isFormValid && !isLoading
                                  ? Colors.white
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildHeader() {
    return [
      const SizedBox(height: 8),
      Text(
        'Hubungkan Aplikasi',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Masukkan Kode Aktivasi untuk menghubungkan aplikasi ke server perusahaan Anda.',
        style: GoogleFonts.inter(
          fontSize: 12,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }

  List<Widget> _buildField() {
    return [
      RichText(
        text: TextSpan(
          text: 'Kode Aktivasi ',
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
      const SizedBox(height: 10),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SizedBox(
            height: 52,
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildCodeInput(
                    controller: _firstController,
                    focusNode: _firstFocus,
                    nextFocus: _secondFocus,
                    prevFocus: null,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildCodeInput(
                    controller: _secondController,
                    focusNode: _secondFocus,
                    nextFocus: _thirdFocus,
                    prevFocus: _firstFocus,
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildCodeInput(
                    controller: _thirdController,
                    focusNode: _thirdFocus,
                    nextFocus: _fourthFocus,
                    prevFocus: _secondFocus,
                    index: 2,
                  ),
                ),
                Text(
                  '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: _buildCodeInput(
                    controller: _fourthController,
                    focusNode: _fourthFocus,
                    nextFocus: _fifthFocus,
                    prevFocus: _thirdFocus,
                    index: 3,
                  ),
                ),
                Expanded(
                  child: _buildCodeInput(
                    controller: _fifthController,
                    focusNode: _fifthFocus,
                    nextFocus: _sixthFocus,
                    prevFocus: _fourthFocus,
                    index: 4,
                  ),
                ),
                Expanded(
                  child: _buildCodeInput(
                    controller: _sixthController,
                    focusNode: _sixthFocus,
                    nextFocus: null,
                    prevFocus: _fifthFocus,
                    index: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildErrorMessage() {
    return Selector<AuthProvider, String?>(
      selector: (_, p) => p.errorMessage,
      builder: (_, errorMessage, _) {
        if (errorMessage == null) {
          return const SizedBox.shrink();
        }

        return ExceptionContainer(errorMessage: errorMessage, marginTop: 32);
      },
    );
  }
}
