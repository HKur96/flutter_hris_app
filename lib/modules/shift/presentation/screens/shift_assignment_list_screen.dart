import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../employee_management/presentation/provider/employee_management_provider.dart';
import '../../domain/entity/shift_assignment.dart';
import '../provider/shift_assignment_provider.dart';
import '../provider/shift_provider.dart';
import 'bulk_assignment_screen.dart';
import 'shift_list_screen.dart';

/// Screen Utama Daftar Penugasan Shift (Stitch Mockup 01, 02, 08, 09, 10)
/// Menampilkan jadwal operasional tim, quick date range bar, filter aktif, dual action (+ Tunggal & + Massal),
/// serta state resilience (loading shimmer, error retry, dan empty state).
class ShiftAssignmentListScreen extends StatefulWidget {
  const ShiftAssignmentListScreen({super.key});

  @override
  State<ShiftAssignmentListScreen> createState() =>
      _ShiftAssignmentListScreenState();
}

class _ShiftAssignmentListScreenState extends State<ShiftAssignmentListScreen> {
  @override
  Widget build(BuildContext context) {
    final asgProvider = context.watch<ShiftAssignmentProvider>();
    final assignments = asgProvider.assignments;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Penugasan Shift',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Jadwal operasional harian tim',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Navigasi ke Master Template Shift (Tahap 4)
          IconButton(
            tooltip: 'Master Shift',
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShiftListScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Quick Date Range Bar (Mockup 01)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Periode: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        asgProvider.activeDateRangeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _openFilterModal(context),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: asgProvider.hasActiveFilter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Active Filter Chips Display (Mockup 02)
            if (asgProvider.hasActiveFilter)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (asgProvider.startDate != null &&
                        asgProvider.endDate != null)
                      _buildActiveFilterChip(
                        label:
                            '${asgProvider.startDate} s/d ${asgProvider.endDate}',
                        onDelete: () => asgProvider.clearDateRange(),
                      ),
                    if (asgProvider.selectedShiftName != null)
                      _buildActiveFilterChip(
                        label: asgProvider.selectedShiftName!,
                        onDelete: () => asgProvider.clearShiftFilter(),
                      ),
                    if (asgProvider.selectedEmployeeName != null)
                      _buildActiveFilterChip(
                        label: asgProvider.selectedEmployeeName!,
                        onDelete: () => asgProvider.clearEmployeeFilter(),
                      ),
                  ],
                ),
              ),

            // 3. Content Area: Shimmer / Error / Empty / List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await asgProvider.fetchAssignments(isRefresh: true);
                },
                child: asgProvider.isLoading
                    ? _buildLoadingShimmer()
                    : asgProvider.errorMessage != null
                    ? _buildErrorState(context, asgProvider.errorMessage!)
                    : assignments.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount: assignments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = assignments[index];
                          return _buildAssignmentCard(item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF065F46),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  /// Assignment Item Card sesuai Stitch Mockup 01
  Widget _buildAssignmentCard(ShiftAssignment item) {
    final bool isOvernight = item.isOvernight;
    final bool isToday = item.isToday;

    // Background color avatar bervariasi sesuai hash inisial
    final Color avatarBg = _getAvatarColor(item.employeeName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isToday ? const Color(0xFF86EFAC) : AppColors.border,
          width: isToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris 1: Avatar, Nama, NIK & Badge Tanggal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.employeeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'NIK: ${item.employeeNik ?? "-"}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primaryLight
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: isToday ? const Color(0xFFA7F3D0) : AppColors.border,
                  ),
                ),
                child: Text(
                  isToday ? 'HARI INI' : item.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Header Baris 2: Shift Name & Time Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: isOvernight
                        ? const Color(0xFF7E22CE)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.shiftName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOvernight
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: isOvernight
                        ? const Color(0xFFE9D5FF)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  item.formattedTimeRange,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOvernight
                        ? const Color(0xFF7E22CE)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      const Color(0xFF2563EB), // Blue
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFD97706), // Amber
      const Color(0xFF059669), // Emerald
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  /// Shimmer Loading Skeleton State sesuai Mockup 09
  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State sesuai Stitch Mockup 08
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 28,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Penugasan Shift',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Karyawan belum memiliki jadwal shift pada periode ini. Buat penugasan baru secara individu atau massal.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Buat Penugasan Shift',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BulkAssignmentScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error State dengan Tombol Coba Lagi sesuai Stitch Mockup 10
  Widget _buildErrorState(BuildContext context, String error) {
    final asgProvider = context.read<ShiftAssignmentProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 28,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gagal Memuat Jadwal Shift',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
                onPressed: () => asgProvider.fetchAssignments(isRefresh: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filter Bottom Sheet Modal sesuai Stitch Mockup 02
  void _openFilterModal(BuildContext context) {
    final asgProvider = context.read<ShiftAssignmentProvider>();
    final shiftProvider = context.read<ShiftProvider>();
    final empProvider = context.read<EmployeeManagementProvider>();

    String? tempStartDate = asgProvider.startDate;
    String? tempEndDate = asgProvider.endDate;
    String? tempShiftId = asgProvider.selectedShiftId;
    String? tempShiftName = asgProvider.selectedShiftName;
    String? tempEmpId = asgProvider.selectedEmployeeId;
    String? tempEmpName = asgProvider.selectedEmployeeName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Penugasan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempStartDate = null;
                              tempEndDate = null;
                              tempShiftId = null;
                              tempShiftName = null;
                              tempEmpId = null;
                              tempEmpName = null;
                            });
                          },
                          child: Text(
                            'Reset Filter',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 14),

                    // Filter Tanggal Mulai & Tanggal Selesai
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tgl Mulai',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: modalContext,
                                    initialDate:
                                        DateTime.tryParse(
                                          tempStartDate ?? '2026-11-21',
                                        ) ??
                                        DateTime.now(),
                                    firstDate: DateTime(2025, 1, 1),
                                    lastDate: DateTime(2030, 12, 31),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tempStartDate =
                                          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    });
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.medium,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    tempStartDate ?? 'Pilih Tgl',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tgl Selesai',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: modalContext,
                                    initialDate:
                                        DateTime.tryParse(
                                          tempEndDate ?? '2026-11-27',
                                        ) ??
                                        DateTime.now(),
                                    firstDate: DateTime(2025, 1, 1),
                                    lastDate: DateTime(2030, 12, 31),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tempEndDate =
                                          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    });
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.medium,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    tempEndDate ?? 'Pilih Tgl',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Template Shift
                    Text(
                      'Shift Kerja',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: tempShiftId,
                          hint: const Text('Semua Template Shift'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Template Shift'),
                            ),
                            ...shiftProvider.shifts.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(
                                  '${s.name} (${s.startTime} - ${s.endTime})',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              tempShiftId = val;
                              if (val != null) {
                                tempShiftName = shiftProvider.shifts
                                    .firstWhere((s) => s.id == val)
                                    .name;
                              } else {
                                tempShiftName = null;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filter Karyawan
                    Text(
                      'Karyawan',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: tempEmpId,
                          hint: const Text('Semua Karyawan'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Karyawan'),
                            ),
                            ...empProvider.employees.map(
                              (e) => DropdownMenuItem<String?>(
                                value: e.id,
                                child: Text('${e.name} (${e.nik})'),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              tempEmpId = val;
                              if (val != null) {
                                tempEmpName = empProvider.employees
                                    .firstWhere((e) => e.id == val)
                                    .name;
                              } else {
                                tempEmpName = null;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Terapkan Filter 48dp
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
                        onPressed: () {
                          asgProvider.applyFilter(
                            startDate: tempStartDate,
                            endDate: tempEndDate,
                            shiftId: tempShiftId,
                            shiftName: tempShiftName,
                            employeeId: tempEmpId,
                            employeeName: tempEmpName,
                          );
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
