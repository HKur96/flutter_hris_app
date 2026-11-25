import 'package:fpdart/fpdart.dart';

import '../../../../core/config/base_exception.dart';
import '../entity/shift_assignment.dart';

/// Kontrak Repository Penugasan Shift (Shift Assignment)
abstract class ShiftAssignmentRepository {
  /// Mengambil daftar penugasan shift dengan filter opsional (Modul 4.3: GET /api/v1/shift-assignments)
  Future<Either<BaseException, List<ShiftAssignment>>> getShiftAssignments({
    String? employeeId,
    String? shiftId,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  });

  /// Membuat penugasan shift massal ke banyak karyawan & rentang tanggal (Modul 4.2: POST /api/v1/shift-assignments/bulk)
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
  });
}
