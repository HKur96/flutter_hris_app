import 'package:dio/dio.dart';
import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/core/config/base_response.dart';
import 'package:flutter_hris_app/core/helper/dio_helper.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/modules/auth/data/model/user_model.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/domain/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioHelper _dioHelper = DioHelper();

  @override
  Future<Either<BaseException, User>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final response = await _dioHelper.postRequest(
        'api/v1/auth/login',
        requestBody: {'email': email, 'password': password},
      );

      final res = BaseResponse<Map<String, dynamic>>.fromJson(response.data);

      if (res.status != 200 && res.error != null && res.data == null) {
        return Left(NetworkException(res.error!.message));
      }

      final user = UserModel.fromJson(res.data!['user']);
      
      await AppSecureStorage().writeToken(res.data!['token']);
      await AppSecureStorage().writeUser(user);

      return Right(user);
    } on DioException catch (e) {
      return Left(NetworkException('llll'));
    } catch (e, s) {
      print('opo seh ndeng gendeng $e\n$s');
      return Left(DataException('Gagal Login'));
    }
  }
}
