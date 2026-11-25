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

/// Screen Utama Daftar Penugasan Shift (Stitch Mockup 01, 02, 08, 09, 10 & Grid Matrix View)
/// Mendukung mode tampilan ganda (Matriks Grid & Kartu), navigasi mingguan (Prev/Next/Hari Ini),
/// multi-shift pada hari yang sama, seleksi massal (bulk update), dan Slot Inspector Bottom Sheet.
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
    final empProvider = context.watch<EmployeeManagementProvider>();
    final shiftProvider = context.watch<ShiftProvider>();

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
          // Navigasi ke Master Template Shift
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
          // Filter Modal Trigger
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Filter Penugasan',
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: asgProvider.hasActiveFilter
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _openFilterModal(context),
              ),
              if (asgProvider.hasActiveFilter)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Mode Seleksi Massal (Batch Update) Trigger
          IconButton(
            tooltip: asgProvider.isSelectionMode
                ? 'Keluar Mode Seleksi'
                : 'Pilih Massal',
            icon: Icon(
              Icons.checklist_rounded,
              color: asgProvider.isSelectionMode
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () => asgProvider.toggleSelectionMode(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Navigation & Segmented View Switcher Header
            _buildNavigationHeader(context, asgProvider),

            // 2. Active Filter Chips Display (jika filter aktif)
            if (asgProvider.hasActiveFilter)
              _buildActiveFilterChips(asgProvider),

            // 3. Konten Utama: Loading / Error / Matriks Grid / Kartu
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
                    : asgProvider.isMatrixView
                    ? _buildMatrixGridView(
                        context,
                        asgProvider,
                        empProvider,
                        shiftProvider,
                      )
                    : _buildCardListView(context, asgProvider),
              ),
            ),
          ],
        ),
      ),
      // Bottom Toolbar saat Mode Seleksi Massal Aktif
      bottomNavigationBar: asgProvider.isSelectionMode
          ? _buildSelectionToolbar(context, asgProvider, shiftProvider)
          : null,
      floatingActionButton: asgProvider.isSelectionMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Penugasan Shift',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
    );
  }

  /// Header Navigasi Tanggal Mingguan + Segmented Switcher (Matriks vs Kartu)
  Widget _buildNavigationHeader(
    BuildContext context,
    ShiftAssignmentProvider asgProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Row 1: Navigasi Minggu (< Periode > + Hari Ini)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => asgProvider.prevWeek(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    asgProvider.weekRangeLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => asgProvider.nextWeek(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => asgProvider.goToToday(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF005B8C),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Segmented Switcher View (Matriks Grid vs Kartu)
          Container(
            height: 36,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => asgProvider.setMatrixView(true),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Container(
                      decoration: BoxDecoration(
                        color: asgProvider.isMatrixView
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        boxShadow: asgProvider.isMatrixView
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_view_week_rounded,
                            size: 15,
                            color: asgProvider.isMatrixView
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Matriks Grid',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: asgProvider.isMatrixView
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: asgProvider.isMatrixView
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => asgProvider.setMatrixView(false),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !asgProvider.isMatrixView
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        boxShadow: !asgProvider.isMatrixView
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_agenda_rounded,
                            size: 15,
                            color: !asgProvider.isMatrixView
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kartu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: !asgProvider.isMatrixView
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: !asgProvider.isMatrixView
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
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
        ],
      ),
    );
  }

  /// Active Filter Chips Bar
  Widget _buildActiveFilterChips(ShiftAssignmentProvider asgProvider) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (asgProvider.selectedShiftName != null)
            _buildActiveFilterChip(
              label: 'Shift: ${asgProvider.selectedShiftName!}',
              onDelete: () => asgProvider.clearShiftFilter(),
            ),
          if (asgProvider.selectedEmployeeName != null)
            _buildActiveFilterChip(
              label: 'Karyawan: ${asgProvider.selectedEmployeeName!}',
              onDelete: () => asgProvider.clearEmployeeFilter(),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF065F46),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 1: MATRIKS GRID VIEW (STITCH MOCKUP)
  // =========================================================================

  Widget _buildMatrixGridView(
    BuildContext context,
    ShiftAssignmentProvider asgProvider,
    EmployeeManagementProvider empProvider,
    ShiftProvider shiftProvider,
  ) {
    final weekDays = asgProvider.weekDays;
    final assignments = asgProvider.assignments;

    // Kumpulkan daftar karyawan dari data master employee & penugasan aktif
    final employees = _collectMatrixEmployees(
      empProvider,
      assignments,
      asgProvider.selectedEmployeeId,
    );

    if (employees.isEmpty) {
      return _buildEmptyState(context);
    }

    const double freezeColWidth = 116.0;
    const double dayColWidth = 66.0;
    const double headerHeight = 46.0;
    const double rowHeight = 62.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sticky Freeze Column (Karyawan Header & List)
          SizedBox(
            width: freezeColWidth,
            child: Column(
              children: [
                // Header Karyawan
                Container(
                  height: headerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5EEFF),
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                      right: BorderSide(color: AppColors.border),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KARYAWAN',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${employees.length} Personil',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Baris Karyawan
                ...employees.map(
                  (emp) => Container(
                    height: rowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                        right: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _getAvatarColor(emp.name),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emp.initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emp.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                emp.subtitle ?? 'Karyawan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Horizontal Scrollable 7-Day Grid
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: 7 * dayColWidth,
                child: Column(
                  children: [
                    // Header 7 Hari (Minggu - Sabtu)
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: weekDays.map((day) {
                          final isToday = _isSameDay(day, DateTime.now());
                          const daysShort = [
                            'SEN',
                            'SEL',
                            'RAB',
                            'KAM',
                            'JUM',
                            'SAB',
                            'MIN',
                          ];
                          final dayName = daysShort[day.weekday - 1];
                          final dayNum = day.day.toString().padLeft(2, '0');

                          return Container(
                            width: dayColWidth,
                            height: headerHeight,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF8FAFC),
                              border: const Border(
                                bottom: BorderSide(color: AppColors.border),
                                right: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isToday
                                        ? const Color(0xFF00652C)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                if (isToday)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00652C),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      dayNum,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    dayNum,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Grid Cells per Karyawan
                    ...employees.map((emp) {
                      return SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: weekDays.map((day) {
                            final dateStr = _formatYmd(day);
                            final dayAssignments = assignments
                                .where(
                                  (a) =>
                                      a.employeeId == emp.id &&
                                      a.workDate == dateStr,
                                )
                                .toList();

                            return _buildMatrixCell(
                              context: context,
                              emp: emp,
                              day: day,
                              dayAssignments: dayAssignments,
                              cellWidth: dayColWidth,
                              cellHeight: rowHeight,
                              asgProvider: asgProvider,
                              shiftProvider: shiftProvider,
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cell Matrix: Menangani Slot Kosong (Libur), Slot Tunggal, Multi-Shift, dan Status Seleksi
  Widget _buildMatrixCell({
    required BuildContext context,
    required _GridEmployeeItem emp,
    required DateTime day,
    required List<ShiftAssignment> dayAssignments,
    required double cellWidth,
    required double cellHeight,
    required ShiftAssignmentProvider asgProvider,
    required ShiftProvider shiftProvider,
  }) {
    final isSelection = asgProvider.isSelectionMode;

    // KASUS 1: Libur / Tidak ada penugasan
    if (dayAssignments.isEmpty) {
      return Container(
        width: cellWidth,
        height: cellHeight,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
            right: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!isSelection) {
              _openEmptyCellDialog(context, emp, day);
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Libur',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // KASUS 2: Single Shift
    if (dayAssignments.length == 1) {
      final item = dayAssignments.first;
      final isSelected = asgProvider.selectedAssignmentIds.contains(item.id);
      final style = _getShiftStyle(item.shiftName, item.isOvernight);

      return Container(
        width: cellWidth,
        height: cellHeight,
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
            right: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (isSelection) {
              asgProvider.toggleAssignmentSelection(item.id);
            } else {
              _showSlotDetailModal(context, item, emp);
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.primary : style.borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _shortShiftName(item.shiftName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: style.textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _compactTimeRange(item.startTime, item.endTime),
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: style.textColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // Indikator Seleksi Checkmark
                if (isSelection)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 13,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // KASUS 3: Multi-Shift Pada Hari Yang Sama (Stitch Double Shift Support)
    final anySelected = dayAssignments.any(
      (a) => asgProvider.selectedAssignmentIds.contains(a.id),
    );

    return Container(
      width: cellWidth,
      height: cellHeight,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isSelection) {
            // Toggle seleksi seluruh shift di hari ini
            for (final a in dayAssignments) {
              asgProvider.toggleAssignmentSelection(a.id);
            }
          } else {
            _showMultiSlotDetailModal(context, dayAssignments, emp, day);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: anySelected ? AppColors.primary : const Color(0xFFCBD5E1),
              width: anySelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dayAssignments.take(2).map((item) {
              final style = _getShiftStyle(item.shiftName, item.isOvernight);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: style.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _shortShiftName(item.shiftName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: style.textColor,
                        ),
                      ),
                    ),
                    Text(
                      _compactTimeRange(item.startTime, item.endTime),
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: style.textColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 2: CARD LIST VIEW (EXISTING STREAMLINED)
  // =========================================================================

  Widget _buildCardListView(
    BuildContext context,
    ShiftAssignmentProvider asgProvider,
  ) {
    final assignments = asgProvider.assignments;

    if (assignments.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = assignments[index];
        final empItem = _GridEmployeeItem(
          id: item.employeeId,
          name: item.employeeName,
          nik: item.employeeNik,
          subtitle: item.employeeRole,
          initials: item.initials,
        );

        final isSelected = asgProvider.selectedAssignmentIds.contains(item.id);

        return InkWell(
          onTap: () {
            if (asgProvider.isSelectionMode) {
              asgProvider.toggleAssignmentSelection(item.id);
            } else {
              _showSlotDetailModal(context, item, empItem);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: _buildAssignmentCard(
            item,
            isSelected,
            asgProvider.isSelectionMode,
          ),
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    ShiftAssignment item,
    bool isSelected,
    bool isSelectionMode,
  ) {
    final bool isOvernight = item.isOvernight;
    final bool isToday = item.isToday;
    final Color avatarBg = _getAvatarColor(item.employeeName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isToday
              ? const Color(0xFF86EFAC)
              : AppColors.border,
          width: isSelected || isToday ? 1.5 : 1.0,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primaryLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFFA7F3D0)
                            : AppColors.border,
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
                  if (isSelectionMode) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
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

  // =========================================================================
  // BOTTOM SHEET INSPECTOR: DETAIL PENUGASAN (STITCH VIEWPORT 2)
  // =========================================================================

  void _showSlotDetailModal(
    BuildContext context,
    ShiftAssignment item,
    _GridEmployeeItem emp,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Penugasan Shift',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  ),
                ],
              ),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),

              // Employee Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _getAvatarColor(emp.name),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emp.initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIK: ${emp.nik ?? "-"} • ${emp.subtitle ?? "Karyawan"}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Shift Details Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANGGAL KERJA',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.formattedFullDateWithDay,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SHIFT TERPASANG',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.shiftName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  item.formattedTimeRange,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JENIS SHIFT',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isOvernight
                                      ? 'Shift Lintas Hari'
                                      : 'Reguler Harian',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: item.isOvernight
                                        ? const Color(0xFF7E22CE)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  item.isOvernight
                                      ? 'Overnight (+1 hari)'
                                      : 'Selesai di hari sama',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons (Ubah & Hapus)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(
                    'Ubah Penugasan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop();
                    _showEditAssignmentModal(context, item);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Hapus Penugasan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop();
                    _confirmDeleteAssignment(context, item);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Inspector Bottom Sheet jika Karyawan memiliki lebih dari 1 shift di hari yang sama
  void _showMultiSlotDetailModal(
    BuildContext context,
    List<ShiftAssignment> dayAssignments,
    _GridEmployeeItem emp,
    DateTime day,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shift Hari Ini (${dayAssignments.length} Shift)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  ),
                ],
              ),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Text(
                'Karyawan: ${emp.name} • ${_formatDayMonth(dayAssignments.first.workDate)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...dayAssignments.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.shiftName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            a.formattedTimeRange,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              Navigator.of(bottomSheetContext).pop();
                              _showEditAssignmentModal(context, a);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              Navigator.of(bottomSheetContext).pop();
                              _confirmDeleteAssignment(context, a);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // MODAL UBAH PENUGASAN SATUAN (PUT /api/v1/shift-assignments/:id)
  // =========================================================================

  void _showEditAssignmentModal(BuildContext context, ShiftAssignment item) {
    final shiftProvider = context.read<ShiftProvider>();
    final asgProvider = context.read<ShiftAssignmentProvider>();

    String selectedShiftId = item.shiftId;
    String selectedWorkDate = item.workDate;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 14,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ubah Penugasan Shift',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Karyawan: ${item.employeeName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 20, color: AppColors.border),

                    // Pilih Shift Baru
                    Text(
                      'Shift Baru Ditugaskan *',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedShiftId,
                          items: shiftProvider.shifts.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.startTime} - ${s.endTime})',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedShiftId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tanggal Kerja (Opsional Pindah Hari)
                    Text(
                      'Tanggal Kerja',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final parsed =
                            DateTime.tryParse(selectedWorkDate) ??
                            DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: parsed,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedWorkDate = _formatYmd(picked);
                          });
                        }
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedWorkDate,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button 48dp
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
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                final success = await asgProvider
                                    .updateShiftAssignment(
                                      id: item.id,
                                      shiftId: selectedShiftId,
                                      workDate:
                                          selectedWorkDate != item.workDate
                                          ? selectedWorkDate
                                          : null,
                                    );
                                setModalState(() => isSubmitting = false);

                                if (context.mounted) {
                                  Navigator.of(modalCtx).pop();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Penugasan shift berhasil diperbarui!',
                                        ),
                                        backgroundColor: Color(0xFF00652C),
                                      ),
                                    );
                                  } else {
                                    _showErrorDialog(
                                      context,
                                      'Gagal Memperbarui Shift',
                                      asgProvider.errorMessage ??
                                          'Terjadi kesalahan server.',
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Terapkan Perubahan'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog Konfirmasi Hapus Penugasan (DELETE /api/v1/shift-assignments/:id)
  void _confirmDeleteAssignment(BuildContext context, ShiftAssignment item) {
    final asgProvider = context.read<ShiftAssignmentProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            'Hapus Penugasan Shift?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Penugasan shift "${item.shiftName}" untuk ${item.employeeName} pada tanggal ${item.formattedDate} akan dihapus.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final success = await asgProvider.deleteShiftAssignment(
                  item.id,
                );
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Penugasan shift berhasil dihapus!'),
                        backgroundColor: Color(0xFF00652C),
                      ),
                    );
                  } else {
                    _showErrorDialog(
                      context,
                      'Gagal Menghapus Shift',
                      asgProvider.errorMessage ?? 'Terjadi kesalahan server.',
                    );
                  }
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TOOLBAR & MODAL SELEKSI MASSAL (BULK UPDATE)
  // =========================================================================

  Widget _buildSelectionToolbar(
    BuildContext context,
    ShiftAssignmentProvider asgProvider,
    ShiftProvider shiftProvider,
  ) {
    final count = asgProvider.selectedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Batal Seleksi',
              onPressed: () => asgProvider.clearSelection(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$count Penugasan Terpilih',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: count > 0
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Ubah Shift'),
              onPressed: count > 0
                  ? () => _showBulkUpdateModal(
                      context,
                      asgProvider.selectedAssignmentIds.toList(),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkUpdateModal(BuildContext context, List<String> assignmentIds) {
    final shiftProvider = context.read<ShiftProvider>();
    final asgProvider = context.read<ShiftAssignmentProvider>();

    if (shiftProvider.shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada template shift tersedia.')),
      );
      return;
    }

    String selectedShiftId = shiftProvider.shifts.first.id;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 14,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ubah Penugasan Massal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Memperbarui ${assignmentIds.length} penugasan shift terpilih sekaligus',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 20, color: AppColors.border),

                    Text(
                      'Shift Baru Ditugaskan *',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedShiftId,
                          items: shiftProvider.shifts.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.startTime} - ${s.endTime})',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedShiftId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                final success = await asgProvider
                                    .updateBulkAssignment(
                                      shiftId: selectedShiftId,
                                      assignmentIds: assignmentIds,
                                    );
                                setModalState(() => isSubmitting = false);

                                if (context.mounted) {
                                  Navigator.of(modalCtx).pop();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${assignmentIds.length} penugasan shift berhasil diperbarui!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF00652C,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showErrorDialog(
                                      context,
                                      'Gagal Ubah Massal',
                                      asgProvider.errorMessage ??
                                          'Terjadi kesalahan server.',
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Terapkan Ubah Massal'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // DIALOG SLOT KOSONG: TAMBAH PENUGASAN SHIFT
  // =========================================================================
  void _openEmptyCellDialog(
    BuildContext context,
    _GridEmployeeItem emp,
    DateTime day,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Jadwalkan Shift',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${emp.name} belum memiliki jadwal shift pada ${_formatDayMonthWithYear(day)}. Tambahkan penugasan baru?',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BulkAssignmentScreen(
                      employeeId: emp.id,
                      selectedDay: day,
                    ),
                  ),
                );
              },
              child: const Text('Buat Penugasan'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER METODE & STATE BUILDERS
  // =========================================================================

  List<_GridEmployeeItem> _collectMatrixEmployees(
    EmployeeManagementProvider empProvider,
    List<ShiftAssignment> assignments,
    String? filterEmployeeId,
  ) {
    final Map<String, _GridEmployeeItem> map = {};

    // 1. Tambahkan seluruh karyawan aktif dari modul employee
    for (final e in empProvider.employees) {
      if (e.isActive) {
        final nikSuffix = e.nik.length >= 4
            ? e.nik.substring(e.nik.length - 4)
            : e.nik;
        final pos = e.position.isNotEmpty ? e.position : e.department;
        map[e.id] = _GridEmployeeItem(
          id: e.id,
          name: e.name,
          nik: e.nik,
          subtitle: '$pos • #$nikSuffix',
          initials: e.initials,
        );
      }
    }

    // 2. Jika ada penugasan karyawan yang belum terdaftar di master
    for (final a in assignments) {
      if (!map.containsKey(a.employeeId)) {
        final nikSuffix = (a.employeeNik?.length ?? 0) >= 4
            ? a.employeeNik!.substring(a.employeeNik!.length - 4)
            : (a.employeeNik ?? '-');
        map[a.employeeId] = _GridEmployeeItem(
          id: a.employeeId,
          name: a.employeeName,
          nik: a.employeeNik,
          subtitle:
              '${a.employeeRole ?? a.employeeDepartment ?? "Karyawan"} • #$nikSuffix',
          initials: a.initials,
        );
      }
    }

    var list = map.values.toList();
    if (filterEmployeeId != null) {
      list = list.where((e) => e.id == filterEmployeeId).toList();
    }
    return list;
  }

  _ShiftStyle _getShiftStyle(String shiftName, bool isOvernight) {
    final lower = shiftName.toLowerCase();
    if (isOvernight || lower.contains('malam')) {
      return const _ShiftStyle(
        bgColor: Color(0xFFEDE9FE),
        textColor: Color(0xFF6D28D9),
        borderColor: Color(0xFFDDD6FE),
      );
    }
    if (lower.contains('siang') || lower.contains('sore')) {
      return const _ShiftStyle(
        bgColor: Color(0xFFE0F2FE),
        textColor: Color(0xFF0284C7),
        borderColor: Color(0xFFBAE6FD),
      );
    }
    // Default: Shift Pagi / Reguler
    return const _ShiftStyle(
      bgColor: Color(0xFFECFDF5),
      textColor: Color(0xFF00652C),
      borderColor: Color(0xFFA7F3D0),
    );
  }

  String _shortShiftName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.contains('pagi')) return 'Pagi';
    if (lower.contains('siang')) return 'Siang';
    if (lower.contains('sore')) return 'Sore';
    if (lower.contains('malam')) return 'Malam';
    final parts = fullName.split(RegExp(r'\s+'));
    return parts.first;
  }

  String _compactTimeRange(String start, String end) {
    String s = start.length >= 5 ? start.substring(0, 5) : start;
    String e = end.length >= 5 ? end.substring(0, 5) : end;
    // Potong menit jika :00
    if (s.endsWith(':00')) s = s.substring(0, 2);
    if (e.endsWith(':00')) e = e.substring(0, 2);
    return '$s-$e';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDayMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatDayMonthWithYear(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF059669),
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

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
        child: Row(
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
      ),
    );
  }

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
              'Karyawan belum memiliki jadwal shift pada periode ini. Buat penugasan baru secara massal.',
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

  void _openFilterModal(BuildContext context) {
    final asgProvider = context.read<ShiftAssignmentProvider>();
    final shiftProvider = context.read<ShiftProvider>();
    final empProvider = context.read<EmployeeManagementProvider>();

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

class _GridEmployeeItem {
  final String id;
  final String name;
  final String? nik;
  final String? subtitle;
  final String initials;

  const _GridEmployeeItem({
    required this.id,
    required this.name,
    this.nik,
    this.subtitle,
    required this.initials,
  });
}

class _ShiftStyle {
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _ShiftStyle({
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}
