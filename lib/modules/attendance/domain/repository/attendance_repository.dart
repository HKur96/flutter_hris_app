import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:fpdart/fpdart.dart';

abstract class AttendanceRepository {
  /// Mendapatkan sesi presensi hari ini untuk pengguna yang sedang login
  Future<Either<BaseException, Attendance?>> getTodayAttendance();

  /// Melakukan check-in mandiri dengan koordinat GPS dan status mock device
  Future<Either<BaseException, Attendance>> checkIn({
    required double lat,
    required double lng,
    bool? isMockLocation,
    bool? rejectMock,
    String? notes,
  });

  /// Melakukan check-out mandiri untuk menyelesaikan sesi kerja harian
  Future<Either<BaseException, Attendance>> checkOut({
    required double lat,
    required double lng,
    String? notes,
  });

  /// Mengambil daftar riwayat presensi (didukung filter kaku sesuai API)
  Future<Either<BaseException, List<Attendance>>> getAttendanceList({
    String? employeeId,
    String? shiftId,
    String? status,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  });

  /// Mendapatkan detail satu rekaman presensi berdasarkan ID
  Future<Either<BaseException, Attendance>> getAttendanceDetail(String id);

  /// Pencatatan presensi manual oleh Owner/Admin (status dikunci ABSENT)
  Future<Either<BaseException, Attendance>> createManualAttendance({
    required String employeeId,
    required String workDate,
    required String shiftId,
    required String status,
    required String notes,
  });

  /// Koreksi status atau catatan presensi oleh Owner/Admin (method override PUT)
  Future<Either<BaseException, Attendance>> adjustAttendance({
    required String id,
    required String status,
    required String notes,
  });
}
