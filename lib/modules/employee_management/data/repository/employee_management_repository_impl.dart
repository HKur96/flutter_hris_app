import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/base_exception.dart';
import '../../../../core/config/base_response.dart';
import '../../../../core/helper/dio_helper.dart';
import '../../../../core/shared/app_secure_storage.dart';
import '../../domain/entity/employee_profile.dart';
import '../../domain/repository/employee_management_repository.dart';
import '../model/employee_profile_model.dart';

class EmployeeManagementRepositoryImpl implements EmployeeManagementRepository {
  final DioHelper _dioHelper = DioHelper.instance;

  @override
  Future<Either<BaseException, List<EmployeeProfile>>> getEmployees({
    String? search,
    String? department,
    String? status,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final queryParams = <String, dynamic>{
        'auth_token': ?token,
        if (search != null && search.isNotEmpty) 'search': search,
        if (department != null && department != 'Semua')
          'department': department,
        if (status != null && status != 'Semua') 'employment_status': status,
      };

      final response = await _dioHelper.getRequest(
        'api/v1/employees',
        queryParameters: queryParams,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final res = BaseResponse<List<dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (jsonList) => jsonList as List<dynamic>,
      );

      if (res.data == null || res.data!.isEmpty) {
        return Right([]);
      }

      final list = res.data!
          .map<EmployeeProfile>(
            (item) =>
                EmployeeProfileModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      return Right(list);
    } on DioException catch (e) {
      debugPrint('DioException on getEmployees: $e');
      return Left(NetworkException('Gagal mengambil data karyawan'));
    } catch (e) {
      debugPrint('Exception on getEmployees: $e');
      return Left(DataException('Gagal memproses data karyawan'));
    }
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> getEmployeeById(
    String id,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final response = await _dioHelper.getRequest(
        'api/v1/employees/$id',
        queryParameters: {'auth_token': ?token},
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (res.data == null) {
        return Right(null);
      }

      return Right(EmployeeProfileModel.fromJson(res.data!));
    } on DioException catch (e) {
      return Left(
        NetworkException(e.response?.data ?? 'Gagal mengambil data karyawan'),
      );
    } catch (_) {
      return Left(DataException('Gagal memproses data karyawan'));
    }
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> createEmployee(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = {'auth_token': ?token, ...payload};

      final response = await _dioHelper.postRequest(
        'api/v1/employees',
        requestBody: body,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (res.data == null) {
        return Right(null);
      }

      // Auto create to user with password = NIK + 123!
      await _dioHelper.postRequest(
        '/api/v1/users',
        requestBody: {
          "auth_token": body['auth_token'],
          "email": body['email'],
          "password": "${body['nik']}123!",
          "role": body['role'],
          "employee_id": res.data!['id'],
          "is_active": true,
        },
      );

      final created = EmployeeProfileModel.fromJson(res.data!);

      return Right(created);
    } on DioException catch (e) {
      return Left(
        NetworkException(e.response?.data ?? 'Gagal menambahkan karyawan'),
      );
    } catch (e, s) {
      debugPrint('Error create employee: $e\n$s');
      return Left(DataException('Gagal menambahkan karyawan'));
    }
  }

  @override
  Future<Either<BaseException, EmployeeProfile?>> updateEmployee(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = {'auth_token': ?token, '_method': 'PUT', ...payload};

      final response = await _dioHelper.postRequest(
        'api/v1/employees/$id',
        requestBody: body,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );

      if (res.data == null) {
        return Right(null);
      }

      final updated = EmployeeProfileModel.fromJson(res.data!);
      return Right(updated);
    } on DioException catch (e) {
      return Left(
        NetworkException(e.response?.data ?? 'Gagal update karyawan'),
      );
    } catch (_) {
      return Left(DataException('Gagal update karyawan'));
    }
  }

  @override
  Future<Either<BaseException, bool>> softDeleteEmployee(String id) async {
    try {
      final token = await AppSecureStorage().readToken();
      await _dioHelper.postRequest(
        'api/v1/employees/$id',
        requestBody: {'auth_token': ?token, '_method': 'DELETE'},
      );

      return const Right(true);
    } catch (_) {
      return Left(DataException('Gagal menonaktifkan karyawan'));
    }
  }
}
