import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/core/config/base_response.dart';
import 'package:flutter_hris_app/core/helper/dio_helper.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/modules/auth/data/model/setup_status_model.dart';
import 'package:flutter_hris_app/modules/auth/data/model/user_model.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
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

      final dynamic rawData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        rawData as Map<String, dynamic>,
      );

      if (res.status != 200 && res.error != null && res.data == null) {
        return Left(NetworkException(res.error!.message));
      }

      final user = UserModel.fromJson(res.data!['user']);
      
      await AppSecureStorage().writeToken(res.data!['token']);
      await AppSecureStorage().writeUser(user);

      return Right(user);
    } on DioException {
      return Left(NetworkException('Gagal terhubung ke server'));
    } catch (e, s) {
      debugPrint('Login exception: $e\n$s');
      return Left(DataException('Gagal Login'));
    }
  }

  @override
  Future<Either<BaseException, SetupStatus>> checkSetupStatus() async {
    try {
      final response = await _dioHelper.getRequest('api/v1/auth/setup-status');

      final dynamic rawData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        rawData as Map<String, dynamic>,
      );

      if (res.status != 200 && res.error != null && res.data == null) {
        return Left(NetworkException(res.error!.message));
      }

      final status = SetupStatusModel.fromJson(res.data!);
      return Right(status);
    } on DioException {
      return Left(NetworkException('Gagal memeriksa status inisialisasi server'));
    } catch (e, s) {
      debugPrint('Check setup status exception: $e\n$s');
      return Left(DataException('Gagal membaca status inisialisasi'));
    }
  }

  @override
  Future<Either<BaseException, User>> setupInitialOwner(
    String email,
    String password,
  ) async {
    try {
      final response = await _dioHelper.postRequest(
        'api/v1/auth/setup-owner',
        requestBody: {'email': email, 'password': password},
      );

      final dynamic rawData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        rawData as Map<String, dynamic>,
      );

      if ((res.status != 200 && res.status != 201) &&
          res.error != null &&
          res.data == null) {
        return Left(NetworkException(res.error!.message));
      }

      final user = UserModel.fromJson(res.data!['user']);

      if (res.data!['token'] != null) {
        await AppSecureStorage().writeToken(res.data!['token']);
      }
      await AppSecureStorage().writeUser(user);

      return Right(user);
    } on DioException {
      return Left(NetworkException('Gagal inisialisasi akun OWNER'));
    } catch (e, s) {
      debugPrint('Setup owner exception: $e\n$s');
      return Left(DataException('Gagal membuat akun OWNER'));
    }
  }
}
