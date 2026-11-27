import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 05 — Riwayat Presensi Saya (Employee Read-Only)
/// Sesuai spesifikasi Stitch Stage 6: Attendance (KaryaHR Mobile).
class AttendanceHistoryScreen extends StatefulWidget {
  final bool showAppBar;

  const AttendanceHistoryScreen({super.key, this.showAppBar = true});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchMyHistory();
    });
  }

  void _applyStatusFilter(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<AttendanceProvider>().fetchMyHistory(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Filter Bar Sesuai API (Status, Shift, Rentang Tgl)
        _buildFilterBar(),

        // List Presensi Read-Only
        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingHistory) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (provider.historyError != null) {
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
                          provider.historyError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton.secondary(
                          text: 'Muat Ulang',
                          onPressed: () => provider.fetchMyHistory(
                            status: _selectedStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.myHistory.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum Ada Riwayat Presensi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data presensi harian Anda akan tampil di sini.',
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
                onRefresh: () =>
                    provider.fetchMyHistory(status: _selectedStatus),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  itemCount: provider.myHistory.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space12),
                  itemBuilder: (context, index) {
                    final item = provider.myHistory[index];
                    return _buildAttendanceCard(item);
                  },
                ),
              );
            },
          ),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Presensi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Bulan Ini',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: content,
    );
  }

  Widget _buildFilterBar() {
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
            _buildFilterChip(
              label: _selectedStatus ?? 'Semua Status',
              isActive: _selectedStatus != null,
              onTap: _showStatusFilterPicker,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Pilih Shift',
              isActive: false,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Rentang Tgl',
              icon: Icons.calendar_today_rounded,
              isActive: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon ?? Icons.expand_more_rounded,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterPicker() {
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

  Widget _buildAttendanceCard(Attendance item) {
    final dateFormatted = DateFormatter.dateTimeToString(
      item.workDate,
      'EEEE, dd MMM yyyy',
    );
    final inTime = item.checkIn != null
        ? DateFormatter.dateTimeToString(item.checkIn!, 'HH:mm')
        : '--:--';
    final outTime = item.checkOut != null
        ? DateFormatter.dateTimeToString(item.checkOut!, 'HH:mm')
        : '--:--';
    final durationStr = item.durationMinutes != null
        ? '${item.durationMinutes!.toInt()} mnt'
        : '-';

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
              Text(
                dateFormatted,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.shiftName.isNotEmpty
                ? item.shiftName
                : 'Shift Pagi Regular (08:00 - 17:00)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // If ABSENT without timestamps
          if (item.status == 'ABSENT')
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                item.notes != null && item.notes!.isNotEmpty
                    ? 'Catatan Admin: ${item.notes}'
                    : 'Dicatat manual oleh Admin: Tidak hadir tanpa konfirmasi.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MASUK',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inTime,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.status == 'LATE'
                                ? AppColors.statusWarning
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KELUAR',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          outTime,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DURASI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          durationStr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = const Color(0xFFD1FAE5); // Emerald 100
        fg = const Color(0xFF065F46); // Emerald 800
        label = 'PRESENT';
        break;
      case 'LATE':
        bg = const Color(0xFFFEF3C7); // Amber 100
        fg = const Color(0xFF92400E); // Amber 800
        label = 'LATE';
        break;
      case 'ABSENT':
        bg = const Color(0xFFFEE2E2); // Red 100
        fg = const Color(0xFF991B1B); // Red 800
        label = 'ABSENT';
        break;
      default:
        bg = AppColors.canvas;
        fg = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
