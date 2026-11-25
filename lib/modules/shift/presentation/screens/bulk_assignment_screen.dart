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
class BulkAssignmentScreen extends StatefulWidget {
  const BulkAssignmentScreen({super.key});

  @override
  State<BulkAssignmentScreen> createState() => _BulkAssignmentScreenState();
}

class _BulkAssignmentScreenState extends State<BulkAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedShiftId;
  String? _selectedShiftName;
  String? _selectedStartTime;
  String? _selectedEndTime;
  bool _selectedIsOvernight = false;

  late String _startDate;
  late String _endDate;
  final Set<String> _selectedEmployeeIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final inFiveDays = now.add(const Duration(days: 4));

    _startDate =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _endDate =
        "${inFiveDays.year.toString().padLeft(4, '0')}-${inFiveDays.month.toString().padLeft(2, '0')}-${inFiveDays.day.toString().padLeft(2, '0')}";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepopulateDefaults();
    });
  }

  void _prepopulateDefaults() {
    final shiftProvider = context.read<ShiftProvider>();
    final activeShifts = shiftProvider.shifts.where((s) => s.isActive).toList();
    if (activeShifts.isNotEmpty && _selectedShiftId == null) {
      final firstShift = activeShifts.first;
      setState(() {
        _selectedShiftId = firstShift.id;
        _selectedShiftName = firstShift.name;
        _selectedStartTime = firstShift.startTime;
        _selectedEndTime = firstShift.endTime;
        _selectedIsOvernight = firstShift.isCrossDayOvernight;
      });
    }

    // Default checklist: pilih 2 karyawan awal jika ada
    final empProvider = context.read<EmployeeManagementProvider>();
    if (empProvider.employees.isNotEmpty && _selectedEmployeeIds.isEmpty) {
      setState(() {
        _selectedEmployeeIds.addAll(
          empProvider.employees.take(2).map((e) => e.id),
        );
      });
    }
  }

  int get _calculatedDays {
    try {
      final s = DateTime.parse(_startDate);
      final e = DateTime.parse(_endDate);
      final diff = e.difference(s).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  int get _estimatedEntries => _calculatedDays * _selectedEmployeeIds.length;

  Future<void> _pickDate({required bool isStart}) async {
    final currentStr = isStart ? _startDate : _endDate;
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
      setState(() {
        if (isStart) {
          _startDate = formatted;
          // Validasi agar endDate tidak lebih kecil dari startDate
          if (_endDate.compareTo(_startDate) < 0) {
            _endDate = _startDate;
          }
        } else {
          _endDate = formatted;
          if (_endDate.compareTo(_startDate) < 0) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _submitBulkAssignment(List<EmployeeProfile> allEmployees) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih template shift terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setidaknya 1 karyawan untuk penugasan massal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedNames = allEmployees
        .where((e) => _selectedEmployeeIds.contains(e.id))
        .map((e) => e.name)
        .toList();

    final asgProvider = context.read<ShiftAssignmentProvider>();
    final result = await asgProvider.createBulkAssignment(
      shiftId: _selectedShiftId!,
      startDate: _startDate,
      endDate: _endDate,
      employeeIds: _selectedEmployeeIds.toList(),
      employeeNames: selectedNames,
      shiftName: _selectedShiftName,
      startTime: _selectedStartTime,
      endTime: _selectedEndTime,
      isOvernight: _selectedIsOvernight,
    );

    if (!mounted) return;

    print('opo jink $result');

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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedShiftId,
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
                                setState(() {
                                  _selectedShiftId = s.id;
                                  _selectedShiftName = s.name;
                                  _selectedStartTime = s.startTime;
                                  _selectedEndTime = s.endTime;
                                  _selectedIsOvernight = s.isCrossDayOvernight;
                                });
                              }
                            },
                          ),
                        ),
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
                                        Text(
                                          _startDate,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
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
                                        Text(
                                          _endDate,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                '${_selectedEmployeeIds.length} Terpilih',
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
                              setState(() {
                                if (_selectedEmployeeIds.length ==
                                    employees.length) {
                                  _selectedEmployeeIds.clear();
                                } else {
                                  _selectedEmployeeIds.addAll(
                                    employees.map((e) => e.id),
                                  );
                                }
                              });
                            },
                            child: Text(
                              _selectedEmployeeIds.length == employees.length
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
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: employees.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final emp = employees[index];
                            final isChecked = _selectedEmployeeIds.contains(
                              emp.id,
                            );

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    _selectedEmployeeIds.remove(emp.id);
                                  } else {
                                    _selectedEmployeeIds.add(emp.id);
                                  }
                                });
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
                                        setState(() {
                                          if (val == true) {
                                            _selectedEmployeeIds.add(emp.id);
                                          } else {
                                            _selectedEmployeeIds.remove(emp.id);
                                          }
                                        });
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
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '${emp.position} • ${emp.department}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
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
                      const SizedBox(height: 16),

                      // Summary Calculation Preview (Hari x Karyawan = Total Entri)
                      DottedBorder(
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
                                value: '$_calculatedDays Hari',
                              ),
                              const SizedBox(height: 6),
                              _buildPreviewRow(
                                label: 'Total Karyawan:',
                                value:
                                    '${_selectedEmployeeIds.length} Karyawan',
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              _buildPreviewRow(
                                label: 'Perkiraan Entri Shift:',
                                value: '$_estimatedEntries Penugasan Baru',
                                isHighlight: true,
                              ),
                            ],
                          ),
                        ),
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
