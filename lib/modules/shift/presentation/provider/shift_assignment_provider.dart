import 'package:flutter/material.dart';

import '../../domain/entity/shift_assignment.dart';
import '../../domain/repository/shift_assignment_repository.dart';
import '../../data/repository/shift_assignment_repository_impl.dart';

/// Provider State Management untuk Penugasan Shift (Shift Assignments)
/// Mengatur daftar roster, filter tanggal/shift/karyawan, deteksi konflik,
/// navigasi mingguan (Grid Matrix), mode seleksi massal, dan mutasi data (update/delete).
class ShiftAssignmentProvider with ChangeNotifier {
  final ShiftAssignmentRepository _repository;

  ShiftAssignmentProvider({ShiftAssignmentRepository? repository})
      : _repository = repository ?? ShiftAssignmentRepositoryImpl() {
    final monday = _normalizeToMonday(DateTime.now());
    _weekStartDate = monday;
    _startDate = _formatYmd(monday);
    _endDate = _formatYmd(monday.add(const Duration(days: 6)));
    fetchAssignments();
  }

  static DateTime _normalizeToMonday(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<ShiftAssignment> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // View Mode: Matriks Grid vs Kartu
  bool _isMatrixView = true;
  bool get isMatrixView => _isMatrixView;

  void setMatrixView(bool value) {
    if (_isMatrixView != value) {
      _isMatrixView = value;
      notifyListeners();
    }
  }

  // Multi-Selection Mode untuk Ubah Penugasan Massal
  bool _isSelectionMode = false;
  final Set<String> _selectedAssignmentIds = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedAssignmentIds => _selectedAssignmentIds;
  int get selectedCount => _selectedAssignmentIds.length;

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedAssignmentIds.clear();
    }
    notifyListeners();
  }

  void toggleAssignmentSelection(String assignmentId) {
    if (_selectedAssignmentIds.contains(assignmentId)) {
      _selectedAssignmentIds.remove(assignmentId);
    } else {
      _selectedAssignmentIds.add(assignmentId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedAssignmentIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // Week Navigation State
  late DateTime _weekStartDate;
  DateTime get weekStartDate => _weekStartDate;
  List<DateTime> get weekDays =>
      List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));

  String get weekRangeLabel {
    final start = _weekStartDate;
    final end = _weekStartDate.add(const Duration(days: 6));
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
    if (start.month == end.month && start.year == end.year) {
      return '${start.day.toString().padLeft(2, '0')} - ${end.day.toString().padLeft(2, '0')} ${months[start.month - 1]} ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day.toString().padLeft(2, '0')} ${months[start.month - 1]} - ${end.day.toString().padLeft(2, '0')} ${months[end.month - 1]} ${start.year}';
    } else {
      return '${start.day.toString().padLeft(2, '0')} ${months[start.month - 1]} ${start.year} - ${end.day.toString().padLeft(2, '0')} ${months[end.month - 1]} ${end.year}';
    }
  }

  void nextWeek() {
    _weekStartDate = _weekStartDate.add(const Duration(days: 7));
    _startDate = _formatYmd(_weekStartDate);
    _endDate = _formatYmd(_weekStartDate.add(const Duration(days: 6)));
    fetchAssignments(isRefresh: true);
  }

  void prevWeek() {
    _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
    _startDate = _formatYmd(_weekStartDate);
    _endDate = _formatYmd(_weekStartDate.add(const Duration(days: 6)));
    fetchAssignments(isRefresh: true);
  }

  void goToToday() {
    _weekStartDate = _normalizeToMonday(DateTime.now());
    _startDate = _formatYmd(_weekStartDate);
    _endDate = _formatYmd(_weekStartDate.add(const Duration(days: 6)));
    fetchAssignments(isRefresh: true);
  }

  // Filter Parameters (Mockup 01 & 02)
  String? _startDate;
  String? _endDate;
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
      _selectedEmployeeId != null;

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

  /// Mengambil daftar penugasan shift dari backend / repository
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
    if (startDate != null && endDate != null) {
      _startDate = startDate;
      _endDate = endDate;
      final dt = DateTime.tryParse(startDate);
      if (dt != null) {
        _weekStartDate = _normalizeToMonday(dt);
      }
    }
    _selectedShiftId = shiftId;
    _selectedShiftName = shiftName;
    _selectedEmployeeId = employeeId;
    _selectedEmployeeName = employeeName;
    await fetchAssignments(isRefresh: true);
  }

  /// Reset semua filter ke default periode mingguan
  Future<void> resetFilter() async {
    _weekStartDate = _normalizeToMonday(DateTime.now());
    _startDate = _formatYmd(_weekStartDate);
    _endDate = _formatYmd(_weekStartDate.add(const Duration(days: 6)));
    _selectedShiftId = null;
    _selectedShiftName = null;
    _selectedEmployeeId = null;
    _selectedEmployeeName = null;
    await fetchAssignments(isRefresh: true);
  }

  Future<void> clearDateRange() async {
    goToToday();
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

  /// Eksekusi penugasan shift massal (POST /api/v1/shift-assignments/bulk)
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
    _errorMessage = null;
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
        fetchAssignments();
        return res;
      },
    );
  }

  /// Memperbarui satu penugasan shift (PUT /api/v1/shift-assignments/:id)
  Future<bool> updateShiftAssignment({
    required String id,
    required String shiftId,
    String? workDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateShiftAssignment(
      id: id,
      shiftId: shiftId,
      workDate: workDate,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (item) {
        _isLoading = false;
        fetchAssignments();
        return true;
      },
    );
  }

  /// Menghapus satu penugasan shift (DELETE /api/v1/shift-assignments/:id)
  Future<bool> deleteShiftAssignment(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.deleteShiftAssignment(id);

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (deletedId) {
        _isLoading = false;
        fetchAssignments();
        return true;
      },
    );
  }

  /// Memperbarui penugasan shift massal (PUT /api/v1/shift-assignments/bulk)
  Future<bool> updateBulkAssignment({
    required String shiftId,
    List<String>? assignmentIds,
    String? startDate,
    String? endDate,
    List<String>? employeeIds,
    String? oldShiftId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateBulkAssignment(
      shiftId: shiftId,
      assignmentIds: assignmentIds,
      startDate: startDate,
      endDate: endDate,
      employeeIds: employeeIds,
      oldShiftId: oldShiftId,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (res) {
        _isLoading = false;
        clearSelection();
        fetchAssignments();
        return true;
      },
    );
  }
}
