import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Future<Either<BaseException, User>> loginUser(
    String email,
    String password,
  );

  Future<Either<BaseException, SetupStatus>> checkSetupStatus();

  Future<Either<BaseException, User>> setupInitialOwner(
    String email,
    String password,
  );

  Future<Either<BaseException, String>> updateStoreSettings(
    String storeName, {
    bool? isShift,
  });

  Future<Either<BaseException, bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Either<BaseException, User>> getMe();
}
