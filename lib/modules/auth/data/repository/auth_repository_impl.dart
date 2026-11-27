import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/core/config/base_response.dart';
import 'package:flutter_hris_app/core/helper/dio_exception_handler.dart';
import 'package:flutter_hris_app/core/helper/dio_helper.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/modules/auth/data/model/setup_status_model.dart';
import 'package:flutter_hris_app/modules/auth/data/model/user_model.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/domain/repository/auth_repository.dart';
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
      
      final token = res.data!['token'] ?? res.data!['access_token'];
      final refreshToken = res.data!['refresh_token'];
      if (token != null) {
        await AppSecureStorage().writeToken(token.toString());
      }
      if (refreshToken != null) {
        await AppSecureStorage().writeRefreshToken(refreshToken.toString());
      }
      await AppSecureStorage().writeUser(user);

      return Right(user);
    } on DioException catch(e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
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

      final token = res.data!['token'] ?? res.data!['access_token'];
      final refreshToken = res.data!['refresh_token'];
      if (token != null) {
        await AppSecureStorage().writeToken(token.toString());
      }
      if (refreshToken != null) {
        await AppSecureStorage().writeRefreshToken(refreshToken.toString());
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

  @override
  Future<Either<BaseException, String>> updateStoreSettings(
    String storeName, {
    bool? isShift,
  }) async {
    try {
      final response = await _dioHelper.putRequest(
        'api/v1/auth/store',
        requestBody: {
          'name': storeName,
          'store_name': storeName,
          'is_shift': ?isShift,
        },
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

      final returnedName =
          res.data?['store_name'] ?? res.data?['name'] ?? storeName;
      return Right(returnedName.toString());
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e, s) {
      debugPrint('Update store name exception: $e\n$s');
      return Left(DataException('Gagal memperbarui nama toko'));
    }
  }

  @override
  Future<Either<BaseException, bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dioHelper.postRequest(
        'api/v1/auth/change-password',
        requestBody: {
          'current_password': oldPassword,
          'new_password': newPassword,
        },
      );

      final dynamic rawData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        rawData as Map<String, dynamic>,
      );

      if (res.status != 200 && res.error != null) {
        return Left(NetworkException(res.error!.message));
      }

      return const Right(true);
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e, s) {
      debugPrint('Change password exception: $e\n$s');
      return Left(DataException('Gagal mengubah kata sandi'));
    }
  }

  @override
  Future<Either<BaseException, User>> getMe() async {
    try {
      final response = await _dioHelper.getRequest('api/v1/auth/me');

      final dynamic rawData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        rawData as Map<String, dynamic>,
      );

      if (res.status != 200 && res.error != null && res.data == null) {
        return Left(NetworkException(res.error!.message));
      }

      final user = UserModel.fromJson(res.data!['user'] ?? res.data!);
      await AppSecureStorage().writeUser(user);
      return Right(user);
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e, s) {
      debugPrint('Get me exception: $e\n$s');
      return Left(DataException('Gagal mengambil data profil'));
    }
  }
}
