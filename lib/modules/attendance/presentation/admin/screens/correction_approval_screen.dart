import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/components.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Screen 08 — Koreksi Data Presensi (Owner/Admin)
/// Sesuai spesifikasi Stitch Stage 6: Attendance (PUT /api/v1/attendance/:id).
/// Membatasi mutasi hanya pada field status dan notes (alasan audit) tanpa client timestamp injection.
class CorrectionApprovalScreen extends StatefulWidget {
  final Attendance? attendance;

  const CorrectionApprovalScreen({super.key, this.attendance});

  @override
  State<CorrectionApprovalScreen> createState() =>
      _CorrectionApprovalScreenState();
}

class _CorrectionApprovalScreenState extends State<CorrectionApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedStatus;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.attendance?.status ?? 'PRESENT';
    _notesController.text = widget.attendance?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveCorrection() async {
    if (!_formKey.currentState!.validate()) return;
    final item = widget.attendance;
    if (item == null) {
      AppSnackBar.show(
        context,
        message: 'Data presensi tidak ditemukan',
        type: SnackBarType.error,
      );
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final success = await provider.adjustAttendance(
      id: item.id,
      status: _selectedStatus,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.show(
        context,
        message: 'Koreksi presensi berhasil disimpan.',
        type: SnackBarType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      final msg = provider.actionError ?? 'Gagal mengoreksi data presensi.';
      AppSnackBar.show(context, message: msg, type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.attendance;
    final dateStr = item != null
        ? DateFormatter.dateTimeToString(item.workDate, 'dd MMM yyyy')
        : '-';
    final shiftStr = item?.shiftName.isNotEmpty == true
        ? item!.shiftName
        : 'Shift Terkait';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Koreksi Data Presensi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Audit & Penyesuaian Status Presensi',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Comparison Card: Nilai Saat Ini vs Nilai Baru
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
                    Text(
                      'PERBANDINGAN KOREKSI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item?.employeeName ?? 'Karyawan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanggal: $dateStr | $shiftStr',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7), // Amber 100
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Saat Ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item?.status ?? '-',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5), // Emerald 100
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Baru',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedStatus,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF065F46),
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
              const SizedBox(height: AppSpacing.space16),

              // Field 1: Status Dropdown
              Text(
                'Ubah Status Presensi *',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PRESENT',
                    child: Text('PRESENT (Hadir Normal)'),
                  ),
                  DropdownMenuItem(
                    value: 'LATE',
                    child: Text('LATE (Terlambat)'),
                  ),
                  DropdownMenuItem(
                    value: 'ABSENT',
                    child: Text('ABSENT (Tidak Hadir)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Sesuai enum sah modul attendance API Contract.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Field 2: Alasan Koreksi (notes, wajib untuk audit)
              Text(
                'Alasan Koreksi *',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 255,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan koreksi wajib diisi untuk rekam jejak audit.';
                  }
                  return null;
                },
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan penyesuaian status presensi...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.space12),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),

              // Notice Box (Zero AI-Slop & API Contract Compliance)
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Blue 50
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE), // Blue 200
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'API tidak menyediakan pengubahan jam check-in/out. Koreksi hanya mengubah status akhir dan catatan audit.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF1E40AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Action Buttons
              Consumer<AttendanceProvider>(
                builder: (context, provider, _) {
                  return AppButton.primary(
                    text: 'Simpan Perubahan Koreksi',
                    isLoading: provider.isSubmittingAction,
                    onPressed: provider.isSubmittingAction
                        ? null
                        : () => _handleSaveCorrection(),
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
    );
  }
}
