import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/core/utils/currency_input_formatter.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../../core/helper/validator.dart';
import '../../domain/entity/employee_profile.dart';
import '../provider/employee_management_provider.dart';

/// Mockup 03 & 06: Form Tambah Karyawan Baru & Edit Karyawan.
class AddEditEmployeeScreen extends StatefulWidget {
  final EmployeeProfile? employeeToEdit;

  const AddEditEmployeeScreen({super.key, this.employeeToEdit});

  bool get isEditMode => employeeToEdit != null;

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nikController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _positionController;
  late final TextEditingController _salaryController;

  final ValueNotifier<DateTime> _selectedJoinDate = ValueNotifier(
    DateTime.now(),
  );
  final ValueNotifier<Role> _selectedRole = ValueNotifier(Role.employee);

  @override
  void initState() {
    super.initState();
    final edit = widget.employeeToEdit;
    _nikController = TextEditingController(text: edit?.nik ?? '');
    _nameController = TextEditingController(text: edit?.name ?? '');
    _emailController = TextEditingController(text: edit?.email ?? '');
    _phoneController = TextEditingController(text: edit?.phone ?? '');
    _departmentController = TextEditingController(text: edit?.department ?? '');
    _positionController = TextEditingController(text: edit?.position ?? '');
    _salaryController = TextEditingController(
      text: edit != null ? edit.baseSalary.toString() : '',
    );

    if (edit != null) {
      if (edit.joinDate != null) {
        _selectedJoinDate.value = edit.joinDate!;
      }
      if (edit.role != null && edit.role!.isNotEmpty) {
        _selectedRole.value = edit.role!.toUpperCase() == 'ADMIN'
            ? Role.admin
            : Role.employee;
      } else if (edit.position.toLowerCase().contains('admin') ||
          edit.department.toLowerCase().contains('admin')) {
        _selectedRole.value = Role.admin;
      }
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _selectedJoinDate.dispose();
    _selectedRole.dispose();
    super.dispose();
  }

  Future<void> _selectJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate.value,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedJoinDate.value) {
      _selectedJoinDate.value = picked;
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'nik': _nikController.text.trim(),
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'department': _departmentController.text.trim(),
      'position': _positionController.text.trim(),
      'role': _selectedRole.value == Role.admin ? 'ADMIN' : 'EMPLOYEE',
      'join_date':
          "${_selectedJoinDate.value.year.toString().padLeft(4, '0')}-${_selectedJoinDate.value.month.toString().padLeft(2, '0')}-${_selectedJoinDate.value.day.toString().padLeft(2, '0')}",
      'employment_status': widget.isEditMode
          ? widget.employeeToEdit!.employmentStatus
          : 'ACTIVE',
      'base_salary':
          int.tryParse(
            _salaryController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
    };

    final provider = context.read<EmployeeManagementProvider>();
    bool success;

    if (widget.isEditMode) {
      success = await provider.updateEmployee(
        widget.employeeToEdit!.id,
        payload,
      );
    } else {
      success = await provider.createEmployee(payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Data karyawan berhasil diperbarui'
                : 'Karyawan baru berhasil ditambahkan',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan data'),
          backgroundColor: AppColors.statusDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditMode ? 'Edit Karyawan' : 'Tambah Karyawan Baru';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Identitas & Kontak
                      _buildSectionHeader('Identitas & Kontak'),
                      const SizedBox(height: AppSpacing.space10),
                      ..._buildIdentityFields(),
                      const SizedBox(height: AppSpacing.space20),

                      // Section 2: Posisi & Gaji Pokok
                      _buildSectionHeader('Posisi & Gaji Pokok'),
                      const SizedBox(height: AppSpacing.space10),
                      ..._buildPositionFields(),
                      const SizedBox(height: AppSpacing.space24),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Submit Button (Height 48dp)
              Selector<EmployeeManagementProvider, bool>(
                selector: (_, p) => p.isLoading,
                builder: (context, isLoading, _) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                          ),
                        ),
                        onPressed: isLoading ? null : _handleSubmit,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                widget.isEditMode
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Karyawan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  List<Widget> _buildIdentityFields() {
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            AppTextField(
              controller: _nikController,
              label: 'NIK (Nomor Induk Kependudukan)',
              isRequired: true,
              hintText: '16 digit NIK KTP',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              validator: Validators.nikValidator,
            ),
            const SizedBox(height: AppSpacing.space12),
            AppTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              isRequired: true,
              hintText: 'Nama lengkap sesuai KTP',
              textCapitalization: TextCapitalization.words,
              validator: (val) =>
                  Validators.regularValidator('Nama lengkap', val),
            ),
            const SizedBox(height: AppSpacing.space12),
            AppTextField(
              controller: _emailController,
              label: 'Email Resmi',
              isRequired: true,
              hintText: 'nama@company.com',
              keyboardType: TextInputType.emailAddress,
              validator: (val) => Validators.emailValidator(val),
            ),
            const SizedBox(height: AppSpacing.space12),
            AppTextField(
              controller: _phoneController,
              label: 'Nomor Telepon / WhatsApp',
              isRequired: true,
              hintText: '0812xxxxxxxx',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              validator: Validators.phoneValidator,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPositionFields() {
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _departmentController,
              label: 'Departemen',
              isRequired: true,
              hintText: 'Contoh: IT',
              textCapitalization: TextCapitalization.words,
              validator: (val) =>
                  Validators.regularValidator('Departemen', val),
            ),
            const SizedBox(height: AppSpacing.space12),
            AppTextField(
              controller: _positionController,
              label: 'Jabatan Posisi',
              isRequired: true,
              hintText: 'Contoh: Backend Developer',
              textCapitalization: TextCapitalization.words,
              validator: (val) => Validators.regularValidator('Jabatan', val),
            ),

            const SizedBox(height: AppSpacing.space12),
            ValueListenableBuilder<Role>(
              valueListenable: _selectedRole,
              builder: (context, selectedRole, _) {
                return AppRoleSlider(
                  value: selectedRole,
                  onChanged: (newRole) {
                    _selectedRole.value = newRole;
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.space12),

            // Tanggal Bergabung
            RichText(
              text: TextSpan(
                text: 'Tanggal Bergabung',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: [
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
            InkWell(
              onTap: _selectJoinDate,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: ValueListenableBuilder<DateTime>(
                valueListenable: _selectedJoinDate,
                builder: (context, selectedJoinDate, child) {
                  return Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.dateTimeToString(
                            selectedJoinDate,
                            'dd MMMM yyyy',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space12),

            AppTextField(
              controller: _salaryController,
              label: 'Gaji Pokok',
              isRequired: true,
              hintText: 'Contoh: 5.500.000',
              textInputAction: TextInputAction.done,
              prefixIcon: Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  'Rp',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (val) =>
                  Validators.regularValidator('Gaji pokok', val),
              onSubmitted: (value) => _handleSubmit(),
            ),
          ],
        ),
      ),
    ];
  }
}
