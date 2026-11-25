import 'package:flutter/material.dart';

import '../../domain/entity/shift_assignment.dart';
import '../../domain/repository/shift_assignment_repository.dart';
import '../../data/repository/shift_assignment_repository_impl.dart';

/// Provider State Management untuk Penugasan Shift (Shift Assignments)
/// Mengatur daftar roster, filter tanggal/shift/karyawan, deteksi konflik, dan eksekusi form tunggal & massal.
class ShiftAssignmentProvider with ChangeNotifier {
  final ShiftAssignmentRepository _repository;

  ShiftAssignmentProvider({ShiftAssignmentRepository? repository})
    : _repository = repository ?? ShiftAssignmentRepositoryImpl() {
    fetchAssignments();
  }

  List<ShiftAssignment> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter Parameters (Mockup 01 & 02)
  String? _startDate = '2026-11-21';
  String? _endDate = '2026-11-27';
  String? _selectedShiftId;
  String? _selectedShiftName;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  List<ShiftAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get selectedShiftId => _selectedShiftId;
  String? get selectedShiftName => _selectedShiftName;
  String? get selectedEmployeeId => _selectedEmployeeId;
  String? get selectedEmployeeName => _selectedEmployeeName;

  int get totalCount => _assignments.length;

  bool get hasActiveFilter =>
      _selectedShiftId != null ||
      _selectedEmployeeId != null ||
      _startDate != null ||
      _endDate != null;

  /// Label rentang tanggal untuk Quick Date Range Bar (Mockup 01)
  String get activeDateRangeLabel {
    if (_startDate != null && _endDate != null) {
      return '${_formatDayMonth(_startDate!)} - ${_formatDayMonth(_endDate!)} 2026';
    } else if (_startDate != null) {
      return 'Sejak ${_formatDayMonth(_startDate!)}';
    } else if (_endDate != null) {
      return 'Hingga ${_formatDayMonth(_endDate!)}';
    }
    return 'Semua Periode';
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

  /// Mengambil daftar penugasan shift dari backend / fallback repository
  Future<void> fetchAssignments({bool isRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    if (isRefresh) notifyListeners();

    final result = await _repository.getShiftAssignments(
      employeeId: _selectedEmployeeId,
      shiftId: _selectedShiftId,
      startDate: _startDate,
      endDate: _endDate,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _assignments = data;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Mengatur parameter filter dan memuat ulang data
  Future<void> applyFilter({
    String? startDate,
    String? endDate,
    String? shiftId,
    String? shiftName,
    String? employeeId,
    String? employeeName,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    _selectedShiftId = shiftId;
    _selectedShiftName = shiftName;
    _selectedEmployeeId = employeeId;
    _selectedEmployeeName = employeeName;
    await fetchAssignments(isRefresh: true);
  }

  /// Reset semua filter ke default periode mingguan
  Future<void> resetFilter() async {
    _startDate = '2026-11-21';
    _endDate = '2026-11-27';
    _selectedShiftId = null;
    _selectedShiftName = null;
    _selectedEmployeeId = null;
    _selectedEmployeeName = null;
    await fetchAssignments(isRefresh: true);
  }

  Future<void> clearDateRange() async {
    _startDate = null;
    _endDate = null;
    await fetchAssignments(isRefresh: true);
  }

  Future<void> clearShiftFilter() async {
    _selectedShiftId = null;
    _selectedShiftName = null;
    await fetchAssignments(isRefresh: true);
  }

  Future<void> clearEmployeeFilter() async {
    _selectedEmployeeId = null;
    _selectedEmployeeName = null;
    await fetchAssignments(isRefresh: true);
  }

  /// Deteksi konflik penugasan: apakah karyawan sudah ditugaskan pada tanggal kerja ini
  bool checkConflict(String employeeId, String workDate) {
    return _assignments.any(
      (a) => a.employeeId == employeeId && a.workDate == workDate,
    );
  }

  /// Eksekusi penugasan shift massal (Mockup 04 & 05)
  Future<BulkAssignmentResult?> createBulkAssignment({
    required String shiftId,
    required String startDate,
    required String endDate,
    required List<String> employeeIds,
    List<String>? employeeNames,
    String? shiftName,
    String? startTime,
    String? endTime,
    bool? isOvernight,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.createBulkAssignment(
      shiftId: shiftId,
      startDate: startDate,
      endDate: endDate,
      employeeIds: employeeIds,
      employeeNames: employeeNames,
      shiftName: shiftName,
      startTime: startTime,
      endTime: endTime,
      isOvernight: isOvernight,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        notifyListeners();
        return null;
      },
      (res) {
        // Muat ulang daftar assignment agar penugasan baru langsung masuk
        fetchAssignments();
        return res;
      },
    );
  }
}
