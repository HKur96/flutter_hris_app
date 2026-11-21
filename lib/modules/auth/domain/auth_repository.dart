import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Future<Either<BaseException, User>> loginUser(
    String email,
    String password,
  );
}
