import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 07 — Pencatatan Presensi Manual (Owner/Admin)
/// Form ketat 5 field sesuai API Contract POST /api/v1/attendance:
/// employee_id, work_date, shift_id, status (ABSENT), notes
class ManualAttendanceDialog extends StatefulWidget {
  const ManualAttendanceDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ManualAttendanceDialog(),
    );
  }

  @override
  State<ManualAttendanceDialog> createState() => _ManualAttendanceDialogState();
}

class _ManualAttendanceDialogState extends State<ManualAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _selectedShiftId;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormatter.dateTimeToString(
      _selectedDate,
      'yyyy-MM-dd',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeManagementProvider>().fetchEmployees();
      context.read<ShiftProvider>().fetchShifts();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormatter.dateTimeToString(
          picked,
          'yyyy-MM-dd',
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      AppSnackBar.show(
        context,
        message: 'Silakan pilih karyawan terlebih dahulu',
        type: SnackBarType.warning,
      );
      return;
    }
    if (_selectedShiftId == null) {
      AppSnackBar.show(
        context,
        message: 'Silakan pilih shift terkait',
        type: SnackBarType.warning,
      );
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final success = await provider.createManualAttendance(
      employeeId: _selectedEmployeeId!,
      workDate: _dateController.text.trim(),
      shiftId: _selectedShiftId!,
      status: 'ABSENT', // Locked to ABSENT per API contract
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.show(
        context,
        message: 'Presensi manual (ABSENT) berhasil dicatat.',
        type: SnackBarType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      final msg = provider.actionError ?? 'Gagal mencatat presensi manual.';
      AppSnackBar.show(context, message: msg, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pencatatan Presensi Manual',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Khusus Penugasan & Absen Staf',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),

                // Field 1: employee_id
                Text(
                  'Pilih Karyawan *',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Consumer<EmployeeManagementProvider>(
                  builder: (context, empProv, _) {
                    final employees = empProv.employees;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      hint: Text(
                        '-- Pilih Karyawan --',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: employees.map((emp) {
                        return DropdownMenuItem<String>(
                          value: emp.id,
                          child: Text(
                            '${emp.name} (${emp.nik.isNotEmpty ? emp.nik : 'Karyawan'})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEmployeeId = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space12),

                // Field 2: work_date
                Text(
                  'Tanggal Kerja *',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: _dateController,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Format baku: YYYY-MM-DD',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Field 3: shift_id
                Text(
                  'Pilih Shift Kerja *',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Consumer<ShiftProvider>(
                  builder: (context, shiftProv, _) {
                    final shifts = shiftProv.shifts;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedShiftId,
                      hint: Text(
                        '-- Pilih Shift Terkait --',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: shifts.map((shift) {
                        return DropdownMenuItem<String>(
                          value: shift.id,
                          child: Text(
                            '${shift.name} (${shift.startTime} - ${shift.endTime})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedShiftId = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space12),

                // Field 4: Status (Locked to ABSENT as per API contract)
                Text(
                  'Status Presensi (Otomatis)',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2), // Red 100
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: AppColors.statusDanger,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ABSENT (Tidak Hadir / Alpa)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Field 5: notes (Required for audit)
                Text(
                  'Catatan Alasan *',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  maxLength: 255,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Catatan alasan wajib diisi untuk audit presensi.';
                    }
                    return null;
                  },
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Wajib diisi: contoh "Karyawan tidak hadir tanpa keterangan".',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.space12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Action Buttons
                Consumer<AttendanceProvider>(
                  builder: (context, provider, _) {
                    return AppButton.primary(
                      text: 'Simpan Presensi',
                      isLoading: provider.isSubmittingAction,
                      onPressed: provider.isSubmittingAction
                          ? null
                          : () => _handleSubmit(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton.secondary(
                  text: 'Batal',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
