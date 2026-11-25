import 'package:fpdart/fpdart.dart';
import '../../../../core/config/base_exception.dart';
import '../entity/shift.dart';

abstract class ShiftRepository {
  Future<Either<BaseException, List<Shift>>> getShifts({
    String? search,
    bool? isActive,
  });

  Future<Either<BaseException, Shift>> getShiftById(String id);

  Future<Either<BaseException, Shift>> createShift(Map<String, dynamic> payload);

  Future<Either<BaseException, Shift>> updateShift(
    String id,
    Map<String, dynamic> payload,
  );

  Future<Either<BaseException, Shift>> toggleShiftStatus(
    String id,
    bool isActive,
  );
}
