import 'package:flutter/foundation.dart';
import 'package:flutter_hris_app/core/config/base_provider.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/domain/repository/attendance_repository.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceProvider extends BaseProvider<AttendanceRepository> {
  AttendanceProvider({required super.repository});

  // ==========================================
  // GPS & DEVICE PERMISSION STATE
  // ==========================================
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _isFetchingLocation = false;
  bool get isFetchingLocation => _isFetchingLocation;

  bool _isLocationDenied = false;
  bool get isLocationDenied => _isLocationDenied;

  bool _isLocationDeniedForever = false;
  bool get isLocationDeniedForever => _isLocationDeniedForever;

  bool _isMockDetected = false;
  bool get isMockDetected => _isMockDetected;

  String? _locationError;
  String? get locationError => _locationError;

  bool _mockStateLockedForTest = false;

  Future<bool> determineLocation({bool forceRequest = false}) async {
    if (_mockStateLockedForTest) {
      return !_isLocationDenied && !_isMockDetected;
    }

    _isFetchingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _isLocationDenied = true;
        _locationError = 'Layanan lokasi/GPS tidak aktif pada perangkat.';
        _isFetchingLocation = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && forceRequest) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _isLocationDenied = true;
        _isLocationDeniedForever = false;
        _locationError = 'Izin lokasi ditolak.';
        _isFetchingLocation = false;
        notifyListeners();
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocationDenied = true;
        _isLocationDeniedForever = true;
        _locationError =
            'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi.';
        _isFetchingLocation = false;
        notifyListeners();
        return false;
      }

      _isLocationDenied = false;
      _isLocationDeniedForever = false;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentPosition = position;
      _isMockDetected = position.isMocked;
      _isFetchingLocation = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('determineLocation error: $e');
      _isFetchingLocation = false;
      _locationError = 'Gagal memperoleh koordinat GPS: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  void setPositionForTest(Position position) {
    _currentPosition = position;
    _isFetchingLocation = false;
    _isLocationDenied = false;
    _isLocationDeniedForever = false;
    _isMockDetected = position.isMocked;
    _mockStateLockedForTest = true;
    notifyListeners();
  }

  void setLocationStateForTest({
    bool isDenied = false,
    bool isDeniedForever = false,
    bool isMock = false,
  }) {
    _isLocationDenied = isDenied;
    _isLocationDeniedForever = isDeniedForever;
    _isMockDetected = isMock;
    _isFetchingLocation = false;
    _mockStateLockedForTest = true;
    notifyListeners();
  }

  void resetMockDetection() {
    _isMockDetected = false;
    _mockStateLockedForTest = false;
    notifyListeners();
  }

  // ==========================================
  // TODAY'S ATTENDANCE SESSION STATE
  // ==========================================
  Attendance? _todayAttendance;
  Attendance? get todayAttendance => _todayAttendance;
  Attendance? get attendance => _todayAttendance; // alias for backwards compatibility

  bool _isLoadingToday = false;
  bool get isLoadingToday => _isLoadingToday;

  String? _todayError;
  String? get todayError => _todayError;

  bool get hasActiveCheckIn =>
      _todayAttendance != null &&
      _todayAttendance!.checkIn != null &&
      _todayAttendance!.checkOut == null;

  bool get isCompletedToday =>
      _todayAttendance != null &&
      _todayAttendance!.checkIn != null &&
      _todayAttendance!.checkOut != null;

  bool get isClockedIn => _todayAttendance != null && _todayAttendance!.checkIn != null;
  bool get isClockedOut => _todayAttendance != null && _todayAttendance!.checkOut != null;

  bool get isAttendingToday {
    if (_todayAttendance == null) return false;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final workDateStr = _todayAttendance!.workDate.toIso8601String().split('T').first;
    return todayStr == workDateStr;
  }

  String? get status {
    if (!isAttendingToday) return 'Belum Absen';
    if (isClockedOut) return 'Selesai';
    if (isClockedIn) return 'Kerja';
    return null;
  }

  Future<void> fetchTodayAttendance() async {
    _isLoadingToday = true;
    _todayError = null;
    notifyListeners();

    final result = await repository.getTodayAttendance();
    result.fold(
      (error) {
        _todayError = error.message;
        _todayAttendance = null;
        _isLoadingToday = false;
        notifyListeners();
      },
      (data) {
        _todayAttendance = data;
        _isLoadingToday = false;
        notifyListeners();
      },
    );
  }

  // Backwards compatibility for dashboard checkCurrentAttendance
  Future<void> checkCurrentAttendance() async {
    await fetchTodayAttendance();
  }

  // ==========================================
  // CLOCK IN & CLOCK OUT ACTIONS
  // ==========================================
  bool _isSubmittingClock = false;
  bool get isSubmittingClock => _isSubmittingClock;

  String? _clockError;
  String? get clockError => _clockError;

  Future<bool> executeCheckIn({
    String? notes,
    bool rejectMock = false,
  }) async {
    if (_currentPosition == null) {
      final hasLoc = await determineLocation(forceRequest: true);
      if (!hasLoc || _currentPosition == null) return false;
    }

    _isSubmittingClock = true;
    _clockError = null;
    notifyListeners();

    final result = await repository.checkIn(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      isMockLocation: _isMockDetected,
      rejectMock: rejectMock,
      notes: notes,
    );

    return result.fold(
      (error) {
        _clockError = error.message;
        _isSubmittingClock = false;
        notifyListeners();
        return false;
      },
      (data) {
        _todayAttendance = data;
        _isSubmittingClock = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> executeCheckOut({String? notes}) async {
    if (_currentPosition == null) {
      final hasLoc = await determineLocation(forceRequest: true);
      if (!hasLoc || _currentPosition == null) return false;
    }

    _isSubmittingClock = true;
    _clockError = null;
    notifyListeners();

    final result = await repository.checkOut(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      notes: notes,
    );

    return result.fold(
      (error) {
        _clockError = error.message;
        _isSubmittingClock = false;
        notifyListeners();
        return false;
      },
      (data) {
        _todayAttendance = data;
        _isSubmittingClock = false;
        notifyListeners();
        return true;
      },
    );
  }

  // ==========================================
  // ATTENDANCE LIST (ADMIN MONITORING)
  // ==========================================
  List<Attendance> _attendanceList = [];
  List<Attendance> get attendanceList => _attendanceList;

  bool _isLoadingList = false;
  bool get isLoadingList => _isLoadingList;

  String? _listError;
  String? get listError => _listError;

  String? filterEmployeeId;
  String? filterShiftId;
  String? filterStatus;
  String? filterStartDate;
  String? filterEndDate;

  int _pageIndex = 1;
  int get pageIndex => _pageIndex;
  final int pageSize = 10;
  int _totalRecords = 0;
  int get totalRecords => _totalRecords;

  void setFilters({
    String? employeeId,
    String? shiftId,
    String? status,
    String? startDate,
    String? endDate,
  }) {
    filterEmployeeId = employeeId;
    filterShiftId = shiftId;
    filterStatus = status;
    filterStartDate = startDate;
    filterEndDate = endDate;
    _pageIndex = 1;
    notifyListeners();
  }

  Future<void> fetchAttendanceList({bool refresh = false}) async {
    if (refresh) {
      _pageIndex = 1;
    }
    _isLoadingList = true;
    _listError = null;
    notifyListeners();

    final offset = (_pageIndex - 1) * pageSize;
    final result = await repository.getAttendanceList(
      employeeId: filterEmployeeId,
      shiftId: filterShiftId,
      status: filterStatus,
      startDate: filterStartDate,
      endDate: filterEndDate,
      limit: pageSize,
      offset: offset,
    );

    result.fold(
      (error) {
        _listError = error.message;
        _attendanceList = [];
        _isLoadingList = false;
        notifyListeners();
      },
      (list) {
        _attendanceList = list;
        _totalRecords = list.length >= pageSize ? _pageIndex * pageSize + 5 : list.length;
        _isLoadingList = false;
        notifyListeners();
      },
    );
  }

  void nextPage() {
    _pageIndex++;
    fetchAttendanceList();
  }

  void prevPage() {
    if (_pageIndex > 1) {
      _pageIndex--;
      fetchAttendanceList();
    }
  }

  // ==========================================
  // MY ATTENDANCE HISTORY (EMPLOYEE)
  // ==========================================
  List<Attendance> _myHistory = [];
  List<Attendance> get myHistory => _myHistory;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  String? _historyError;
  String? get historyError => _historyError;

  Future<void> fetchMyHistory({
    String? status,
    String? shiftId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    final result = await repository.getAttendanceList(
      status: status,
      shiftId: shiftId,
      startDate: startDate,
      endDate: endDate,
      limit: 50,
      offset: 0,
    );

    result.fold(
      (error) {
        _historyError = error.message;
        _myHistory = [];
        _isLoadingHistory = false;
        notifyListeners();
      },
      (list) {
        _myHistory = list;
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // DETAIL PRESENSI
  // ==========================================
  Attendance? _selectedAttendance;
  Attendance? get selectedAttendance => _selectedAttendance;

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailError;
  String? get detailError => _detailError;

  void setSelectedAttendance(Attendance att) {
    _selectedAttendance = att;
    notifyListeners();
  }

  Future<void> fetchAttendanceDetail(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    final result = await repository.getAttendanceDetail(id);
    result.fold(
      (error) {
        _detailError = error.message;
        _isLoadingDetail = false;
        notifyListeners();
      },
      (data) {
        _selectedAttendance = data;
        _isLoadingDetail = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // MANUAL ATTENDANCE & ADJUSTMENT (ADMIN/OWNER)
  // ==========================================
  bool _isSubmittingAction = false;
  bool get isSubmittingAction => _isSubmittingAction;

  String? _actionError;
  String? get actionError => _actionError;

  Future<bool> createManualAttendance({
    required String employeeId,
    required String workDate,
    required String shiftId,
    required String status,
    required String notes,
  }) async {
    _isSubmittingAction = true;
    _actionError = null;
    notifyListeners();

    final result = await repository.createManualAttendance(
      employeeId: employeeId,
      workDate: workDate,
      shiftId: shiftId,
      status: status,
      notes: notes,
    );

    return result.fold(
      (error) {
        _actionError = error.message;
        _isSubmittingAction = false;
        notifyListeners();
        return false;
      },
      (data) {
        _isSubmittingAction = false;
        // Refresh list
        fetchAttendanceList(refresh: true);
        return true;
      },
    );
  }

  Future<bool> adjustAttendance({
    required String id,
    required String status,
    required String notes,
  }) async {
    _isSubmittingAction = true;
    _actionError = null;
    notifyListeners();

    final result = await repository.adjustAttendance(
      id: id,
      status: status,
      notes: notes,
    );

    return result.fold(
      (error) {
        _actionError = error.message;
        _isSubmittingAction = false;
        notifyListeners();
        return false;
      },
      (updated) {
        _selectedAttendance = updated;
        _isSubmittingAction = false;
        fetchAttendanceList(refresh: true);
        return true;
      },
    );
  }
}
