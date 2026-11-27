import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/core/theme/app_theme.dart';
import 'package:flutter_hris_app/modules/auth/domain/repository/auth_repository.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/domain/repository/attendance_repository.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/domain/entity/employee_profile.dart';
import 'package:flutter_hris_app/modules/employee_management/domain/repository/employee_management_repository.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/shift/domain/entity/shift.dart';
import 'package:flutter_hris_app/modules/shift/domain/entity/shift_assignment.dart';
import 'package:flutter_hris_app/modules/shift/domain/repository/shift_assignment_repository.dart';
import 'package:flutter_hris_app/modules/shift/domain/repository/shift_repository.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_assignment_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';

import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return Position(
      longitude: 106.8456,
      latitude: -6.2088,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 1.0,
    );
  }
}

/// Konfigurasi global pengujian: Nonaktifkan runtime font network fetch & inisialisasi secure storage mock
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;
  GeolocatorPlatform.instance = MockGeolocatorPlatform();
}

// =============================================================================
// FAKE REPOSITORIES (PURE DART IN-MEMORY TANGGUH TANPA MOCKITO/CODE-GEN)
// =============================================================================

/// Fake Auth Repository
class FakeAuthRepository implements AuthRepository {
  SetupStatus setupStatus;
  final Map<String, User> users = {};
  bool shouldFail = false;
  String failMessage = 'Terjadi kesalahan autentikasi';

  FakeAuthRepository({
    SetupStatus? initialSetupStatus,
  }) : setupStatus = initialSetupStatus ??
            const SetupStatus(
              needsSetup: false,
              hasOwner: true,
              totalUsers: 1,
              activeOwners: 1,
              message: 'Setup is complete',
            );

  @override
  Future<Either<BaseException, SetupStatus>> checkSetupStatus() async {
    if (shouldFail) return Left(NetworkException(failMessage));
    return Right(setupStatus);
  }

  @override
  Future<Either<BaseException, User>> loginUser(
    String email,
    String password,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final user = users[email];
    if (user != null) {
      return Right(user);
    }
    // Jika user belum ada di map, buat mock user default
    final newUser = User(
      id: 'user-${email.hashCode}',
      name: email.split('@').first,
      employeeId: 'emp-${email.hashCode}',
      email: email,
      role: email.contains('admin')
          ? Role.admin
          : (email.contains('owner') ? Role.owner : Role.employee),
      isActive: true,
      storeName: 'Toko Berkah Uji',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    users[email] = newUser;
    return Right(newUser);
  }

  @override
  Future<Either<BaseException, User>> setupInitialOwner(
    String email,
    String password,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final owner = User(
      id: 'owner-id-1',
      name: 'Owner Toko',
      employeeId: '',
      email: email,
      role: Role.owner,
      isActive: true,
      storeName: 'KaryaHR Store',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    users[email] = owner;
    setupStatus = const SetupStatus(
      needsSetup: false,
      hasOwner: true,
      totalUsers: 1,
      activeOwners: 1,
      message: 'Setup complete',
    );
    return Right(owner);
  }

  @override
  Future<Either<BaseException, String>> updateStoreSettings(
    String storeName, {
    bool? isShift,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    // Perbarui storeName & isShift pada user yang aktif jika ada
    if (users.isNotEmpty) {
      final firstKey = users.keys.first;
      users[firstKey] = users[firstKey]!.copyWith(
        storeName: storeName,
        isShift: isShift ?? users[firstKey]!.isShift,
      );
    }
    return Right(storeName);
  }

  @override
  Future<Either<BaseException, bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    return const Right(true);
  }

  @override
  Future<Either<BaseException, User>> getMe() async {
    if (shouldFail) return Left(NetworkException(failMessage));
    if (users.isNotEmpty) {
      return Right(users.values.first);
    }
    return Right(User(
      id: 'mock-1',
      name: 'Budi Santoso',
      employeeId: 'emp-1',
      email: 'budi.santoso@tokoberkah.com',
      role: Role.owner,
      isActive: true,
      storeName: 'PT Berkah Makmur Sejahtera',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
}

/// Fake Employee Management Repository
class FakeEmployeeManagementRepository implements EmployeeManagementRepository {
  final List<EmployeeProfile> employees = [];
  bool shouldFail = false;
  String failMessage = 'Error employee management';

  FakeEmployeeManagementRepository({List<EmployeeProfile>? initialEmployees}) {
    if (initialEmployees != null) {
      employees.addAll(initialEmployees);
    } else {
      employees.addAll([
        EmployeeProfile(
          id: 'emp-1',
          nik: '35780101',
          name: 'Siti Aminah',
          email: 'siti@karyahr.com',
          phone: '081234567890',
          department: 'Operasional',
          position: 'Kasir Utama',
          role: 'EMPLOYEE',
          joinDate: DateTime(2025, 1, 1),
          employmentStatus: 'ACTIVE',
          baseSalary: 4500000,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        EmployeeProfile(
          id: 'emp-2',
          nik: '35780102',
          name: 'Ahmad Fauzi',
          email: 'fauzi@karyahr.com',
          phone: '081234567891',
          department: 'Gudang',
          position: 'Staf Logistik',
          role: 'EMPLOYEE',
          joinDate: DateTime(2025, 2, 1),
          employmentStatus: 'ACTIVE',
          baseSalary: 4200000,
          createdAt: DateTime(2025, 2, 1),
          updatedAt: DateTime(2025, 2, 1),
        ),
      ]);
    }
  }

  @override
  Future<Either<BaseException, List<EmployeeProfile>>> getEmployees({
    String? search,
    String? department,
    String? status,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    var result = List<EmployeeProfile>.from(employees);
    if (search != null && search.isNotEmpty) {
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(search.toLowerCase()) ||
              e.nik.contains(search))
          .toList();
    }
    if (status != null && status != 'Semua') {
      final active = status.toLowerCase().contains('aktif') &&
          !status.toLowerCase().contains('non');
      result = result.where((e) => e.isActive == active).toList();
    }
    return Right(result);
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> getEmployeeById(
    String id,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final emp = employees.where((e) => e.id == id).firstOrNull;
    return Right(emp);
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> createEmployee(
    Map<String, dynamic> payload,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final newEmp = EmployeeProfile(
      id: 'emp-${DateTime.now().millisecondsSinceEpoch}',
      nik: payload['nik']?.toString() ?? '35789999',
      name: payload['name']?.toString() ?? 'Baru',
      email: payload['email']?.toString() ?? 'baru@karyahr.com',
      phone: payload['phone']?.toString() ?? '0812000000',
      department: payload['department']?.toString() ?? 'Umum',
      position: payload['position']?.toString() ?? 'Staf',
      role: payload['role']?.toString() ?? 'EMPLOYEE',
      joinDate: DateTime.tryParse(payload['join_date']?.toString() ?? '') ??
          DateTime.now(),
      employmentStatus: 'ACTIVE',
      baseSalary: (payload['base_salary'] as num?)?.toDouble() ?? 4000000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    employees.add(newEmp);
    return Right(newEmp);
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> updateEmployee(
    String id,
    Map<String, dynamic> payload,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final index = employees.indexWhere((e) => e.id == id);
    if (index == -1) return Left(DataException('Karyawan tidak ditemukan'));
    final old = employees[index];
    final updated = EmployeeProfile(
      id: old.id,
      nik: payload['nik']?.toString() ?? old.nik,
      name: payload['name']?.toString() ?? old.name,
      email: payload['email']?.toString() ?? old.email,
      phone: payload['phone']?.toString() ?? old.phone,
      department: payload['department']?.toString() ?? old.department,
      position: payload['position']?.toString() ?? old.position,
      role: payload['role']?.toString() ?? old.role,
      joinDate: old.joinDate,
      employmentStatus: payload['employment_status']?.toString() ??
          old.employmentStatus,
      baseSalary: (payload['base_salary'] as num?)?.toDouble() ?? old.baseSalary,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    employees[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<BaseException, bool>> softDeleteEmployee(String id) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final index = employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final old = employees[index];
      employees[index] = EmployeeProfile(
        id: old.id,
        nik: old.nik,
        name: old.name,
        email: old.email,
        phone: old.phone,
        department: old.department,
        position: old.position,
        role: old.role,
        joinDate: old.joinDate,
        employmentStatus: 'INACTIVE',
        baseSalary: old.baseSalary,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      return const Right(true);
    }
    return Left(DataException('Karyawan tidak ditemukan'));
  }
}

/// Fake Shift Repository
class FakeShiftRepository implements ShiftRepository {
  final List<Shift> shifts = [];
  bool shouldFail = false;
  String failMessage = 'Error shift management';

  FakeShiftRepository({List<Shift>? initialShifts}) {
    if (initialShifts != null) {
      shifts.addAll(initialShifts);
    } else {
      shifts.addAll([
        const Shift(
          id: 'shift-1',
          name: 'Shift Pagi',
          startTime: '08:00',
          endTime: '17:00',
          breakMinutes: 60,
          lateToleranceMinutes: 15,
          isActive: true,
          isOvernight: false,
          grossWorkingMinutes: 540,
          netWorkingMinutes: 480,
        ),
        const Shift(
          id: 'shift-2',
          name: 'Shift Siang',
          startTime: '13:00',
          endTime: '21:00',
          breakMinutes: 60,
          lateToleranceMinutes: 15,
          isActive: true,
          isOvernight: false,
          grossWorkingMinutes: 480,
          netWorkingMinutes: 420,
        ),
        const Shift(
          id: 'shift-3',
          name: 'Shift Malam',
          startTime: '22:00',
          endTime: '06:00',
          breakMinutes: 60,
          lateToleranceMinutes: 15,
          isActive: true,
          isOvernight: true,
          grossWorkingMinutes: 480,
          netWorkingMinutes: 420,
        ),
      ]);
    }
  }

  @override
  Future<Either<BaseException, List<Shift>>> getShifts({
    String? search,
    bool? isActive,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    var list = List<Shift>.from(shifts);
    if (search != null && search.isNotEmpty) {
      list = list
          .where((s) => s.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (isActive != null) {
      list = list.where((s) => s.isActive == isActive).toList();
    }
    return Right(list);
  }

  @override
  Future<Either<BaseException, Shift>> getShiftById(String id) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final s = shifts.where((item) => item.id == id).firstOrNull;
    if (s != null) return Right(s);
    return Left(DataException('Shift tidak ditemukan'));
  }

  @override
  Future<Either<BaseException, Shift>> createShift(
    Map<String, dynamic> payload,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final newShift = Shift(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      name: payload['name']?.toString() ?? 'Shift Baru',
      startTime: payload['start_time']?.toString() ?? '08:00',
      endTime: payload['end_time']?.toString() ?? '17:00',
      breakMinutes: (payload['break_minutes'] as num?)?.toInt() ?? 60,
      lateToleranceMinutes:
          (payload['late_tolerance_minutes'] as num?)?.toInt() ?? 15,
      isActive: payload['is_active'] != false,
      isOvernight: payload['is_overnight'] == true,
    );
    shifts.add(newShift);
    return Right(newShift);
  }

  @override
  Future<Either<BaseException, Shift>> updateShift(
    String id,
    Map<String, dynamic> payload,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final idx = shifts.indexWhere((s) => s.id == id);
    if (idx == -1) return Left(DataException('Shift tidak ditemukan'));
    final old = shifts[idx];
    final updated = Shift(
      id: old.id,
      name: payload['name']?.toString() ?? old.name,
      startTime: payload['start_time']?.toString() ?? old.startTime,
      endTime: payload['end_time']?.toString() ?? old.endTime,
      breakMinutes:
          (payload['break_minutes'] as num?)?.toInt() ?? old.breakMinutes,
      lateToleranceMinutes:
          (payload['late_tolerance_minutes'] as num?)?.toInt() ??
              old.lateToleranceMinutes,
      isActive: payload['is_active'] ?? old.isActive,
      isOvernight: payload['is_overnight'] ?? old.isOvernight,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    shifts[idx] = updated;
    return Right(updated);
  }

  @override
  Future<Either<BaseException, Shift>> toggleShiftStatus(
    String id,
    bool isActive,
  ) async {
    return updateShift(id, {'is_active': isActive});
  }
}

/// Fake Shift Assignment Repository
class FakeShiftAssignmentRepository implements ShiftAssignmentRepository {
  final List<ShiftAssignment> assignments = [];
  bool shouldFail = false;
  String failMessage = 'Error shift assignment';

  FakeShiftAssignmentRepository({List<ShiftAssignment>? initialAssignments}) {
    if (initialAssignments != null) {
      assignments.addAll(initialAssignments);
    } else {
      assignments.addAll([
        const ShiftAssignment(
          id: 'asg-1',
          employeeId: 'emp-1',
          employeeName: 'Siti Aminah',
          employeeNik: '35780101',
          employeeRole: 'Kasir',
          shiftId: 'shift-1',
          shiftName: 'Shift Pagi',
          startTime: '08:00',
          endTime: '17:00',
          workDate: '2026-11-22', // Minggu
          isOvernight: false,
        ),
        const ShiftAssignment(
          id: 'asg-2',
          employeeId: 'emp-1',
          employeeName: 'Siti Aminah',
          employeeNik: '35780101',
          employeeRole: 'Kasir',
          shiftId: 'shift-1',
          shiftName: 'Shift Pagi',
          startTime: '08:00',
          endTime: '17:00',
          workDate: '2026-11-23', // Senin
          isOvernight: false,
        ),
      ]);
    }
  }

  @override
  Future<Either<BaseException, List<ShiftAssignment>>> getShiftAssignments({
    String? employeeId,
    String? shiftId,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    var list = List<ShiftAssignment>.from(assignments);
    if (employeeId != null && employeeId.isNotEmpty) {
      list = list.where((a) => a.employeeId == employeeId).toList();
    }
    if (shiftId != null && shiftId.isNotEmpty) {
      list = list.where((a) => a.shiftId == shiftId).toList();
    }
    return Right(list);
  }

  @override
  Future<Either<BaseException, BulkAssignmentResult>> createBulkAssignment({
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
    if (shouldFail) return Left(NetworkException(failMessage));
    int createdCount = 0;
    final start = DateTime.tryParse(startDate) ?? DateTime.now();
    final end = DateTime.tryParse(endDate) ?? DateTime.now();
    final days = end.difference(start).inDays + 1;

    for (int i = 0; i < (days > 0 ? days : 1); i++) {
      final currentDay = start.add(Duration(days: i));
      final dateStr =
          "${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}";

      for (int j = 0; j < employeeIds.length; j++) {
        final empId = employeeIds[j];
        final empName = (employeeNames != null && j < employeeNames.length)
            ? employeeNames[j]
            : 'Karyawan $empId';

        assignments.add(
          ShiftAssignment(
            id: 'asg-bulk-${DateTime.now().millisecondsSinceEpoch}-$i-$j',
            employeeId: empId,
            employeeName: empName,
            shiftId: shiftId,
            shiftName: shiftName ?? 'Shift Pagi',
            startTime: startTime ?? '08:00',
            endTime: endTime ?? '17:00',
            workDate: dateStr,
            isOvernight: isOvernight ?? false,
          ),
        );
        createdCount++;
      }
    }

    return Right(
      BulkAssignmentResult(
        count: createdCount,
        totalDays: days > 0 ? days : 1,
        totalEmployees: employeeIds.length,
        employeeNames: employeeNames ?? [],
        startDate: startDate,
        endDate: endDate,
        shiftName: shiftName ?? 'Shift Pagi',
      ),
    );
  }

  @override
  Future<Either<BaseException, ShiftAssignment>> updateShiftAssignment({
    required String id,
    required String shiftId,
    String? workDate,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final idx = assignments.indexWhere((a) => a.id == id);
    if (idx == -1) return Left(DataException('Penugasan shift tidak ditemukan'));
    final old = assignments[idx];
    final updated = ShiftAssignment(
      id: old.id,
      employeeId: old.employeeId,
      employeeName: old.employeeName,
      employeeNik: old.employeeNik,
      employeeRole: old.employeeRole,
      shiftId: shiftId,
      shiftName: shiftId == 'shift-2' ? 'Shift Siang' : 'Shift Pagi',
      startTime: shiftId == 'shift-2' ? '13:00' : '08:00',
      endTime: shiftId == 'shift-2' ? '21:00' : '17:00',
      workDate: workDate ?? old.workDate,
      isOvernight: old.isOvernight,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    assignments[idx] = updated;
    return Right(updated);
  }

  @override
  Future<Either<BaseException, String>> deleteShiftAssignment(String id) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final idx = assignments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      assignments.removeAt(idx);
      return Right(id);
    }
    return Left(DataException('Penugasan shift tidak ditemukan'));
  }

  @override
  Future<Either<BaseException, BulkUpdateResult>> updateBulkAssignment({
    required String shiftId,
    List<String>? assignmentIds,
    String? startDate,
    String? endDate,
    List<String>? employeeIds,
    String? oldShiftId,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final targetIds = assignmentIds ?? [];
    for (final id in targetIds) {
      final idx = assignments.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final old = assignments[idx];
        assignments[idx] = ShiftAssignment(
          id: old.id,
          employeeId: old.employeeId,
          employeeName: old.employeeName,
          employeeNik: old.employeeNik,
          employeeRole: old.employeeRole,
          shiftId: shiftId,
          shiftName: shiftId == 'shift-2' ? 'Shift Siang' : 'Shift Malam',
          startTime: shiftId == 'shift-2' ? '13:00' : '22:00',
          endTime: shiftId == 'shift-2' ? '21:00' : '06:00',
          workDate: old.workDate,
          isOvernight: shiftId != 'shift-2',
        );
      }
    }
    return Right(
      BulkUpdateResult(
        count: targetIds.length,
        updatedIds: targetIds,
        newShiftId: shiftId,
        newShiftName: shiftId == 'shift-2' ? 'Shift Siang' : 'Shift Malam',
      ),
    );
  }
}

/// Fake Attendance Repository
class FakeAttendanceRepository implements AttendanceRepository {
  Attendance? todayAttendance;
  List<Attendance> attendanceList = [];
  bool shouldFail = false;
  String failMessage = 'Terjadi kesalahan presensi';

  FakeAttendanceRepository({
    this.todayAttendance,
    List<Attendance>? initialList,
  }) : attendanceList = initialList ?? [];

  @override
  Future<Either<BaseException, Attendance?>> getTodayAttendance() async {
    if (shouldFail) return Left(NetworkException(failMessage));
    return Right(todayAttendance);
  }

  @override
  Future<Either<BaseException, Attendance>> checkIn({
    required double lat,
    required double lng,
    bool? isMockLocation,
    bool? rejectMock,
    String? notes,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final att = Attendance(
      id: 'att-today',
      employeeId: 'emp-1',
      workDate: DateTime.now(),
      shiftId: 'shift-1',
      checkIn: DateTime.now(),
      checkOut: null,
      checkInLat: lat,
      checkInLng: lng,
      checkOutLat: null,
      checkOutLng: null,
      status: 'PRESENT',
      notes: notes,
      employeeName: 'Budi Santoso',
      employeeNik: '3201234567890001',
      shiftName: 'Shift Pagi',
      shiftStartTime: '08:00',
      shiftEndTime: '17:00',
      durationMinutes: null,
    );
    todayAttendance = att;
    return Right(att);
  }

  @override
  Future<Either<BaseException, Attendance>> checkOut({
    required double lat,
    required double lng,
    String? notes,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final att = Attendance(
      id: todayAttendance?.id ?? 'att-today',
      employeeId: todayAttendance?.employeeId ?? 'emp-1',
      workDate: todayAttendance?.workDate ?? DateTime.now(),
      shiftId: todayAttendance?.shiftId ?? 'shift-1',
      checkIn:
          todayAttendance?.checkIn ??
          DateTime.now().subtract(const Duration(hours: 8)),
      checkOut: DateTime.now(),
      checkInLat: todayAttendance?.checkInLat ?? lat,
      checkInLng: todayAttendance?.checkInLng ?? lng,
      checkOutLat: lat,
      checkOutLng: lng,
      status: todayAttendance?.status ?? 'PRESENT',
      notes: notes,
      employeeName: todayAttendance?.employeeName ?? 'Budi Santoso',
      employeeNik: todayAttendance?.employeeNik ?? '3201234567890001',
      shiftName: todayAttendance?.shiftName ?? 'Shift Pagi',
      shiftStartTime: todayAttendance?.shiftStartTime ?? '08:00',
      shiftEndTime: todayAttendance?.shiftEndTime ?? '17:00',
      durationMinutes: 480,
    );
    todayAttendance = att;
    return Right(att);
  }

  @override
  Future<Either<BaseException, List<Attendance>>> getAttendanceList({
    String? employeeId,
    String? shiftId,
    String? status,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    return Right(attendanceList);
  }

  @override
  Future<Either<BaseException, Attendance>> getAttendanceDetail(
    String id,
  ) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final match = attendanceList.where((a) => a.id == id).firstOrNull;
    if (match != null) return Right(match);
    if (todayAttendance != null && todayAttendance!.id == id) {
      return Right(todayAttendance!);
    }
    return Left(DataException('Detail presensi tidak ditemukan'));
  }

  @override
  Future<Either<BaseException, Attendance>> createManualAttendance({
    required String employeeId,
    required String workDate,
    required String shiftId,
    required String status,
    required String notes,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final att = Attendance(
      id: 'att-manual-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      workDate: DateTime.tryParse(workDate) ?? DateTime.now(),
      shiftId: shiftId,
      checkIn: null,
      checkOut: null,
      checkInLat: null,
      checkInLng: null,
      checkOutLat: null,
      checkOutLng: null,
      status: status,
      notes: notes,
      employeeName: 'Karyawan Uji',
      employeeNik: '320100000000',
      shiftName: 'Shift Terkait',
      shiftStartTime: '08:00',
      shiftEndTime: '17:00',
      durationMinutes: null,
    );
    attendanceList.add(att);
    return Right(att);
  }

  @override
  Future<Either<BaseException, Attendance>> adjustAttendance({
    required String id,
    required String status,
    required String notes,
  }) async {
    if (shouldFail) return Left(NetworkException(failMessage));
    final index = attendanceList.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = attendanceList[index];
      final updated = Attendance(
        id: old.id,
        employeeId: old.employeeId,
        workDate: old.workDate,
        shiftId: old.shiftId,
        checkIn: old.checkIn,
        checkOut: old.checkOut,
        checkInLat: old.checkInLat,
        checkInLng: old.checkInLng,
        checkOutLat: old.checkOutLat,
        checkOutLng: old.checkOutLng,
        status: status,
        notes: notes,
        employeeName: old.employeeName,
        employeeNik: old.employeeNik,
        shiftName: old.shiftName,
        shiftStartTime: old.shiftStartTime,
        shiftEndTime: old.shiftEndTime,
        durationMinutes: old.durationMinutes,
      );
      attendanceList[index] = updated;
      return Right(updated);
    }
    return Left(DataException('Data tidak ditemukan'));
  }
}

// =============================================================================
// TEST APP WRAPPER BUILDER
// =============================================================================

Widget createTestApp({
  required Widget child,
  AuthProvider? authProvider,
  EmployeeManagementProvider? empProvider,
  ShiftProvider? shiftProvider,
  ShiftAssignmentProvider? asgProvider,
  AttendanceProvider? attendanceProvider,
  Map<String, WidgetBuilder>? routes,
  Size screenSize = const Size(390, 844),
}) {
  return MultiProvider(
    providers: [
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider)
      else
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: FakeAuthRepository()),
        ),
      if (empProvider != null)
        ChangeNotifierProvider<EmployeeManagementProvider>.value(
          value: empProvider,
        )
      else
        ChangeNotifierProvider(
          create: (_) => EmployeeManagementProvider(
            repository: FakeEmployeeManagementRepository(),
          ),
        ),
      if (shiftProvider != null)
        ChangeNotifierProvider<ShiftProvider>.value(value: shiftProvider)
      else
        ChangeNotifierProvider(
          create: (_) => ShiftProvider(repository: FakeShiftRepository()),
        ),
      if (asgProvider != null)
        ChangeNotifierProvider<ShiftAssignmentProvider>.value(
          value: asgProvider,
        )
      else
        ChangeNotifierProvider(
          create: (_) => ShiftAssignmentProvider(
            repository: FakeShiftAssignmentRepository(),
          ),
        ),
      if (attendanceProvider != null)
        ChangeNotifierProvider<AttendanceProvider>.value(
          value: attendanceProvider,
        )
      else
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(
            repository: FakeAttendanceRepository(),
          ),
        ),
    ],
    child: MaterialApp(
      navigatorKey: gNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('in', 'ID'),
      supportedLocales: const [Locale('in', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routes: routes ?? {},
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: child,
      ),
    ),
  );
}
