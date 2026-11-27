import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/screens/attendance_detail_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/widgets/manual_attendance_dialog.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 04 — Data Presensi Tim (Owner/Admin)
/// Sesuai spesifikasi Stitch Stage 6: Attendance (GET /api/v1/attendance).
class DailyAttendanceMonitoringScreen extends StatefulWidget {
  final bool showAppBar;

  const DailyAttendanceMonitoringScreen({super.key, this.showAppBar = true});

  @override
  State<DailyAttendanceMonitoringScreen> createState() =>
      _DailyAttendanceMonitoringScreenState();
}

class _DailyAttendanceMonitoringScreenState
    extends State<DailyAttendanceMonitoringScreen> {
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchAttendanceList(refresh: true);
    });
  }

  void _applyStatusFilter(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    final provider = context.read<AttendanceProvider>();
    provider.setFilters(
      status: status,
      startDate: _selectedDate != null
          ? DateFormatter.dateTimeToString(_selectedDate!, 'yyyy-MM-dd')
          : null,
      endDate: _selectedDate != null
          ? DateFormatter.dateTimeToString(_selectedDate!, 'yyyy-MM-dd')
          : null,
    );
    provider.fetchAttendanceList(refresh: true);
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
      final provider = context.read<AttendanceProvider>();
      final formatted = DateFormatter.dateTimeToString(picked, 'yyyy-MM-dd');
      provider.setFilters(
        status: _selectedStatus,
        startDate: formatted,
        endDate: formatted,
      );
      provider.fetchAttendanceList(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Filter Row (Query Params: status, date)
        _buildFilterRow(),

        // List Catatan Presensi Tim
        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingList && provider.attendanceList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (provider.listError != null &&
                  provider.attendanceList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: AppColors.statusDanger,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.listError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton.secondary(
                          text: 'Muat Ulang',
                          onPressed: () =>
                              provider.fetchAttendanceList(refresh: true),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.attendanceList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.rule_folder_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak Ada Data Presensi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Belum ada rekaman presensi sesuai filter yang dipilih.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () => provider.fetchAttendanceList(refresh: true),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  itemCount: provider.attendanceList.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space12),
                  itemBuilder: (context, index) {
                    final item = provider.attendanceList[index];
                    return _buildAttendanceItemCard(item);
                  },
                ),
              );
            },
          ),
        ),

        // Pagination Mechanism Footer
        _buildPaginationFooter(),
      ],
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Presensi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pantau & Kelola Kehadiran Tim',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                ),
                icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                label: Text(
                  '+ Manual',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => ManualAttendanceDialog.show(context),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: content,
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              label: _selectedStatus != null
                  ? 'Status: $_selectedStatus'
                  : 'Status: Semua',
              isActive: _selectedStatus != null,
              onTap: _showStatusPicker,
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: _selectedDate != null
                  ? 'Tgl: ${DateFormatter.dateTimeToString(_selectedDate!, 'dd MMM yyyy')}'
                  : 'Tgl: Semua',
              icon: Icons.calendar_today_rounded,
              isActive: _selectedDate != null,
              onTap: _pickFilterDate,
            ),
            if (_selectedDate != null || _selectedStatus != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedDate = null;
                  });
                  final provider = context.read<AttendanceProvider>();
                  provider.setFilters();
                  provider.fetchAttendanceList(refresh: true);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusDanger,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand50 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon ?? Icons.expand_more_rounded,
              size: 13,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Semua Status'),
                trailing: _selectedStatus == null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter(null);
                },
              ),
              ListTile(
                title: const Text('PRESENT (Hadir Normal)'),
                trailing: _selectedStatus == 'PRESENT'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('PRESENT');
                },
              ),
              ListTile(
                title: const Text('LATE (Terlambat)'),
                trailing: _selectedStatus == 'LATE'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('LATE');
                },
              ),
              ListTile(
                title: const Text('ABSENT (Tidak Hadir)'),
                trailing: _selectedStatus == 'ABSENT'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('ABSENT');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceItemCard(Attendance item) {
    final inTimeStr = item.checkIn != null
        ? DateFormatter.dateTimeToString(item.checkIn!, 'HH:mm')
        : '--:--';
    final outTimeStr = item.checkOut != null
        ? DateFormatter.dateTimeToString(item.checkOut!, 'HH:mm')
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.employeeName.isNotEmpty
                        ? item.employeeName
                        : 'Karyawan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIK: ${item.employeeNik.isNotEmpty ? item.employeeNik : '-'}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHIFT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.shiftName.isNotEmpty ? item.shiftName : 'Pagi',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IN',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inTimeStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: item.status == 'LATE'
                            ? AppColors.statusWarning
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OUT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outTimeStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AttendanceDetailScreen(attendance: item),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detail',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'LATE':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'ABSENT':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      default:
        bg = AppColors.canvas;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final page = provider.pageIndex;
        final count = provider.attendanceList.length;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hal $page (Data: $count)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: page > 1 ? () => provider.prevPage() : null,
                    child: Text(
                      'Prev',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: count >= provider.pageSize
                        ? () => provider.nextPage()
                        : null,
                    child: Text(
                      'Next',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
