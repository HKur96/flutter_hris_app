import 'package:fpdart/fpdart.dart';
import '../../../../core/config/base_exception.dart';
import '../entity/employee_profile.dart';

abstract class EmployeeManagementRepository {
  Future<Either<BaseException, List<EmployeeProfile>>> getEmployees({
    String? search,
    String? department,
    String? status,
  });

  Future<Either<BaseException, EmployeeProfile?>> getEmployeeById(String id);

  Future<Either<BaseException, EmployeeProfile?>> createEmployee(
    Map<String, dynamic> payload,
  );

  Future<Either<BaseException, EmployeeProfile?>> updateEmployee(
    String id,
    Map<String, dynamic> payload,
  );

  Future<Either<BaseException, bool>> softDeleteEmployee(String id);
}
