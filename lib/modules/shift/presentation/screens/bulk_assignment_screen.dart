import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../employee_management/domain/entity/employee_profile.dart';
import '../../../employee_management/presentation/provider/employee_management_provider.dart';
import '../../domain/entity/shift.dart';
import '../provider/shift_assignment_provider.dart';
import '../provider/shift_provider.dart';
import 'bulk_assignment_result_screen.dart';

/// Form Penugasan Shift Massal (Stitch Mockup 04 & 07)
/// Menerapkan 1 template shift ke beberapa karyawan sekaligus untuk rentang tanggal (POST /api/v1/shift-assignments/bulk).
/// Dilengkapi kalkulasi simulasi entri (Hari x Karyawan) dan checklist multi-pilihan.
/// Menggunakan [ValueNotifier] sepenuhnya untuk reaktivitas lokal tanpa setState.
class BulkAssignmentScreen extends StatefulWidget {
  final String? employeeId;

  const BulkAssignmentScreen({super.key, this.employeeId});

  @override
  State<BulkAssignmentScreen> createState() => _BulkAssignmentScreenState();
}

class _BulkAssignmentScreenState extends State<BulkAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // State Management Lokal menggunakan ValueNotifier (Zero setState)
  final ValueNotifier<Shift?> _selectedShiftNotifier = ValueNotifier<Shift?>(
    null,
  );
  late final ValueNotifier<String> _startDateNotifier;
  late final ValueNotifier<String> _endDateNotifier;
  final ValueNotifier<Set<String>> _selectedEmployeeIdsNotifier =
      ValueNotifier<Set<String>>({});

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final inFiveDays = now.add(const Duration(days: 4));

    final initialStart =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final initialEnd =
        "${inFiveDays.year.toString().padLeft(4, '0')}-${inFiveDays.month.toString().padLeft(2, '0')}-${inFiveDays.day.toString().padLeft(2, '0')}";

    _startDateNotifier = ValueNotifier<String>(initialStart);
    _endDateNotifier = ValueNotifier<String>(initialEnd);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepopulateDefaults();

      if (widget.employeeId != null) {
        _selectedEmployeeIdsNotifier.value = {widget.employeeId!};
      }
      
    });
  }

  @override
  void dispose() {
    _selectedShiftNotifier.dispose();
    _startDateNotifier.dispose();
    _endDateNotifier.dispose();
    _selectedEmployeeIdsNotifier.dispose();
    super.dispose();
  }

  void _prepopulateDefaults() {
    final shiftProvider = context.read<ShiftProvider>();
    final activeShifts = shiftProvider.shifts.where((s) => s.isActive).toList();
    if (activeShifts.isNotEmpty && _selectedShiftNotifier.value == null) {
      _selectedShiftNotifier.value = activeShifts.first;
    }
  }

  static int _getCalculatedDays(String startStr, String endStr) {
    try {
      final s = DateTime.parse(startStr);
      final e = DateTime.parse(endStr);
      final diff = e.difference(s).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final currentStr = isStart
        ? _startDateNotifier.value
        : _endDateNotifier.value;
    final current = DateTime.tryParse(currentStr) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: isStart ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Selesai',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      if (isStart) {
        _startDateNotifier.value = formatted;
        // Validasi agar endDate tidak lebih kecil dari startDate
        if (_endDateNotifier.value.compareTo(_startDateNotifier.value) < 0) {
          _endDateNotifier.value = _startDateNotifier.value;
        }
      } else {
        _endDateNotifier.value = formatted;
        if (_endDateNotifier.value.compareTo(_startDateNotifier.value) < 0) {
          _startDateNotifier.value = _endDateNotifier.value;
        }
      }
    }
  }

  Future<void> _submitBulkAssignment(List<EmployeeProfile> allEmployees) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedShift = _selectedShiftNotifier.value;
    if (selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih template shift terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedEmpIds = _selectedEmployeeIdsNotifier.value;
    if (selectedEmpIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setidaknya 1 karyawan untuk penugasan massal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedNames = allEmployees
        .where((e) => selectedEmpIds.contains(e.id))
        .map((e) => e.name)
        .toList();

    final asgProvider = context.read<ShiftAssignmentProvider>();
    final result = await asgProvider.createBulkAssignment(
      shiftId: selectedShift.id,
      startDate: _startDateNotifier.value,
      endDate: _endDateNotifier.value,
      employeeIds: selectedEmpIds.toList(),
      employeeNames: selectedNames,
      shiftName: selectedShift.name,
      startTime: selectedShift.startTime,
      endTime: selectedShift.endTime,
      isOvernight: selectedShift.isCrossDayOvernight,
    );

    if (!mounted) return;

    if (result != null) {
      // Navigasi langsung ke Screen 05 (Hasil Penugasan Massal)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BulkAssignmentResultScreen(result: result),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asgProvider.errorMessage ??
                'Gagal mengeksekusi penugasan shift massal.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final empProvider = context.watch<EmployeeManagementProvider>();
    final shiftProvider = context.watch<ShiftProvider>();

    final List<EmployeeProfile> employees = empProvider.employees.isNotEmpty
        ? empProvider.employees
        : [];

    final List<Shift> activeShifts = shiftProvider.shifts.isNotEmpty
        ? shiftProvider.shifts.where((s) => s.isActive).toList()
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Form Penugasan Shift',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Plotting jadwal shift kerja karyawan',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Pilih Template Shift
                      Text(
                        'Pilih Shift',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<Shift?>(
                        valueListenable: _selectedShiftNotifier,
                        builder: (context, selectedShift, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedShift?.id,
                                hint: Text(
                                  'Pilih Shift',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                items: activeShifts.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(
                                      '${s.name} (${s.startTime} - ${s.endTime})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final s = activeShifts.firstWhere(
                                      (item) => item.id == val,
                                    );
                                    _selectedShiftNotifier.value = s;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Rentang Tanggal (Grid 2 Kolom)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tgl Mulai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(isStart: true),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                  child: Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.medium,
                                      ),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable: _startDateNotifier,
                                          builder: (context, startDate, _) {
                                            return Text(
                                              startDate,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            );
                                          },
                                        ),
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tgl Selesai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(isStart: false),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                  child: Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.medium,
                                      ),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable: _endDateNotifier,
                                          builder: (context, endDate, _) {
                                            return Text(
                                              endDate,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            );
                                          },
                                        ),
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Multi-Employee Checklist Selector
                      ValueListenableBuilder<Set<String>>(
                        valueListenable: _selectedEmployeeIdsNotifier,
                        builder: (context, selectedIds, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pilih Karyawan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${selectedIds.length} Terpilih',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (selectedIds.length ==
                                          employees.length) {
                                        _selectedEmployeeIdsNotifier.value =
                                            <String>{};
                                      } else {
                                        _selectedEmployeeIdsNotifier.value =
                                            employees.map((e) => e.id).toSet();
                                      }
                                    },
                                    child: Text(
                                      selectedIds.length == employees.length
                                          ? 'Batal Semua'
                                          : 'Pilih Semua',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // List Container Karyawan dengan Checkbox
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: employees.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                  itemBuilder: (context, index) {
                                    final emp = employees[index];
                                    final isChecked = selectedIds.contains(
                                      emp.id,
                                    );

                                    return InkWell(
                                      onTap: () {
                                        final newSet = Set<String>.from(
                                          selectedIds,
                                        );
                                        if (isChecked) {
                                          newSet.remove(emp.id);
                                        } else {
                                          newSet.add(emp.id);
                                        }
                                        _selectedEmployeeIdsNotifier.value =
                                            newSet;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        color: isChecked
                                            ? const Color(0xFFF0FDF4)
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isChecked,
                                              activeColor: AppColors.primary,
                                              onChanged: (val) {
                                                final newSet = Set<String>.from(
                                                  selectedIds,
                                                );
                                                if (val == true) {
                                                  newSet.add(emp.id);
                                                } else {
                                                  newSet.remove(emp.id);
                                                }
                                                _selectedEmployeeIdsNotifier
                                                        .value =
                                                    newSet;
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    emp.name,
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    '${emp.position} • ${emp.department}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              emp.nik,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Summary Calculation Preview (Hari x Karyawan = Total Entri)
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          _startDateNotifier,
                          _endDateNotifier,
                          _selectedEmployeeIdsNotifier,
                        ]),
                        builder: (context, _) {
                          final days = _getCalculatedDays(
                            _startDateNotifier.value,
                            _endDateNotifier.value,
                          );
                          final totalEmployees =
                              _selectedEmployeeIdsNotifier.value.length;
                          final estimatedEntries = days * totalEmployees;

                          return DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              radius: const Radius.circular(AppRadius.medium),
                              strokeWidth: 0.6,
                              color: Colors.grey,
                              dashPattern: const [6, 4],
                              strokeCap: StrokeCap.round,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.medium,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPreviewRow(
                                    label: 'Rentang Waktu:',
                                    value: '$days Hari',
                                  ),
                                  const SizedBox(height: 6),
                                  _buildPreviewRow(
                                    label: 'Total Karyawan:',
                                    value: '$totalEmployees Karyawan',
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPreviewRow(
                                    label: 'Perkiraan Entri Shift:',
                                    value: '$estimatedEntries Penugasan Baru',
                                    isHighlight: true,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Actions 48dp
            Selector<ShiftAssignmentProvider, bool>(
              selector: (_, p) => p.isLoading,
              builder: (context, isLoading, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _submitBulkAssignment(employees),
                          child: Text(
                            isLoading
                                ? 'Memproses Penugasan...'
                                : 'Simpan Penugasan Shift',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Batalkan',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 13 : 12,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
