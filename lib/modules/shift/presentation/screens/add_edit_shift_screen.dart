import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/helper/validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../domain/entity/shift.dart';
import '../provider/shift_provider.dart';

/// Form Tambah & Ubah Template Shift (Mockup 03 & Mockup 06).
/// Mengimplementasikan kontrak REST Cloudflare Workers Modul 3:
/// - POST /api/v1/shifts (Create)
/// - POST /api/v1/shifts/:id dengan _method: PUT (Update)
/// Mendukung live calculation untuk lintas hari (overnight) dan jam kerja kotor/bersih
/// menggunakan ValueNotifier dan ListenableBuilder tanpa setState.
class AddEditShiftScreen extends StatefulWidget {
  final Shift? shift;

  const AddEditShiftScreen({super.key, this.shift});

  bool get isEdit => shift != null;

  @override
  State<AddEditShiftScreen> createState() => _AddEditShiftScreenState();
}

class _AddEditShiftScreenState extends State<AddEditShiftScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breakController;
  late TextEditingController _lateToleranceController;

  late ValueNotifier<String> _startTime;
  late ValueNotifier<String> _endTime;
  late ValueNotifier<bool> _isActive;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _nameController = TextEditingController(text: s?.name ?? '');
    _startTime = ValueNotifier(s?.startTime ?? '08:00');
    _endTime = ValueNotifier(s?.endTime ?? '17:00');
    _breakController = TextEditingController(
      text: (s?.breakMinutes ?? 60).toString(),
    );
    _lateToleranceController = TextEditingController(
      text: (s?.lateToleranceMinutes ?? 15).toString(),
    );
    _isActive = ValueNotifier(s?.isActive ?? true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breakController.dispose();
    _lateToleranceController.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _isActive.dispose();
    super.dispose();
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      final h = int.parse(parts[0].trim());
      final m = int.parse(parts[1].trim());
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  bool get _isCrossDayOvernight {
    final start = _timeToMinutes(_startTime.value);
    final end = _timeToMinutes(_endTime.value);
    return end <= start;
  }

  int get _grossMinutes {
    final start = _timeToMinutes(_startTime.value);
    final end = _timeToMinutes(_endTime.value);
    if (end > start) {
      return end - start;
    } else {
      return (24 * 60 - start) + end;
    }
  }

  int get _breakMinutes => int.tryParse(_breakController.text.trim()) ?? 0;
  int get _lateToleranceMinutes =>
      int.tryParse(_lateToleranceController.text.trim()) ?? 0;

  int get _netMinutes {
    final net = _grossMinutes - _breakMinutes;
    return net > 0 ? net : 0;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0].trim()),
        minute: int.parse(parts[1].trim()),
      );
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = _parseTimeOfDay(
      isStart ? _startTime.value : _endTime.value,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: isStart ? 'Pilih Jam Mulai Shift' : 'Pilih Jam Selesai Shift',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        _startTime.value = formatted;
      } else {
        _endTime.value = formatted;
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_breakMinutes >= _grossMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Durasi istirahat ($_breakMinutes mnt) tidak boleh melebihi durasi kerja kotor ($_grossMinutes mnt).',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final payload = {
      'name': _nameController.text.trim(),
      'start_time': _startTime.value,
      'end_time': _endTime.value,
      'break_minutes': _breakMinutes,
      'late_tolerance_minutes': _lateToleranceMinutes,
      'is_active': _isActive.value,
    };

    final provider = context.read<ShiftProvider>();
    bool success = false;

    if (widget.isEdit) {
      success = await provider.updateShift(widget.shift!.id, payload);
    } else {
      success = await provider.createShift(payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Template shift berhasil diperbarui.'
                : 'Template shift baru berhasil disimpan.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Gagal menyimpan shift. Silakan coba lagi.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            Text(
              widget.isEdit ? 'Ubah Template Shift' : 'Tambah Shift Baru',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.isEdit)
              Text(
                widget.shift!.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
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
                      // Field 1: Nama Shift
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Shift',
                        hintText: 'cth: Shift Pagi Gudang / Shift Malam',
                        isRequired: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nama template yang akan tampil pada penugasan karyawan.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2 & 3: Jam Mulai & Jam Selesai
                      Row(
                        children: [
                          Expanded(child: _buildStartTimePicker()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildEndTimePicker()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field 4: break_minutes & late_tolerance
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  controller: _breakController,
                                  label: 'Durasi Istirahat',
                                  isRequired: true,
                                  keyboardType: TextInputType.number,
                                  hintText: '60',
                                  suffixText: 'menit',
                                  validator: Validators.breakTimeValidator,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  controller: _lateToleranceController,
                                  label: 'Toleransi Keterlambatan',
                                  isRequired: true,
                                  hintText: '15',
                                  suffixText: 'menit',
                                  keyboardType: TextInputType.number,
                                  validator: Validators.lateToleranceValidator,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field 5: is_active switch
                      if (widget.isEdit) ...[..._buildActiveStatus()],

                      // Live Calculation & Preview Box (Stitch Mockup 03 Contract)
                      _buildLiveCalculation(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Action Buttons 48dp height
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTimePicker() {
    return ValueListenableBuilder<String>(
      valueListenable: _startTime,
      builder: (context, startTime, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Jam Mulai',
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
              onTap: () => _pickTime(isStart: true),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      startTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Format 24 jam',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndTimePicker() {
    return ListenableBuilder(
      listenable: Listenable.merge([_startTime, _endTime]),
      builder: (context, child) {
        final endTime = _endTime.value;
        final isOvernight = _isCrossDayOvernight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Jam Selesai',
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
              onTap: () => _pickTime(isStart: false),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: isOvernight
                        ? Colors.purple.shade300
                        : AppColors.border,
                    width: isOvernight ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      endTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isOvernight
                            ? Colors.purple.shade800
                            : AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      isOvernight
                          ? Icons.nights_stay_rounded
                          : Icons.schedule_rounded,
                      size: 18,
                      color: isOvernight
                          ? Colors.purple.shade700
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (isOvernight)
              Row(
                children: [
                  Icon(
                    Icons.nights_stay_rounded,
                    size: 12,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Lintas tengah malam (+1)',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Hari yang sama (Reguler)',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Selector<ShiftProvider, bool>(
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
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: isLoading ? null : _submitForm,
                  child: Text(
                    isLoading
                        ? 'Menyimpan...'
                        : widget.isEdit
                        ? 'Simpan Perubahan Shift'
                        : 'Simpan Shift Baru',
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
    );
  }

  Widget _buildLiveCalculation() {
    return ListenableBuilder(
      listenable: Listenable.merge([_startTime, _endTime, _breakController]),
      builder: (context, _) {
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
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulasi Otomatis Durasi Kerja',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Durasi Kotor:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_grossMinutes Menit (${(_grossMinutes / 60.0).toStringAsFixed(1)} Jam)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Durasi Bersih Efektif:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '$_netMinutes Menit (${(_netMinutes / 60.0).toStringAsFixed(1)} Jam)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActiveStatus() {
    return [
      ValueListenableBuilder<bool>(
        valueListenable: _isActive,
        builder: (context, isActive, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Shift Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Template aktif langsung dapat dipilih pada penugasan.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    _isActive.value = val;
                  },
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 18),
    ];
  }
}
