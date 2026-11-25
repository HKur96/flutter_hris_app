import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/base_exception.dart';
import '../../../../core/config/base_response.dart';
import '../../../../core/helper/dio_helper.dart';
import '../../../../core/shared/app_secure_storage.dart';
import '../../domain/entity/shift.dart';
import '../../domain/repository/shift_repository.dart';
import '../model/shift_model.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final DioHelper _dioHelper = DioHelper.instance;

  @override
  Future<Either<BaseException, List<Shift>>> getShifts({
    String? search,
    bool? isActive,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final queryParams = <String, dynamic>{
        'auth_token': ?token,
        if (search != null && search.isNotEmpty) 'search': search,
        'is_active': ?isActive,
      };

      final response = await _dioHelper.getRequest(
        'api/v1/shifts',
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
        return Left(DataException('Shift tidak ditemukan'));
      }

      final list = res.data!
          .map<Shift>(
            (item) => ShiftModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on DioException catch (e) {
      debugPrint('DioException on getShifts, fallback to demo dataset: $e');
      return Left(NetworkException(e.response?.data));
    } catch (e) {
      debugPrint('Exception on getShifts: $e');
      return Left(DataException(e.toString()));
    }
  }

  @override
  Future<Either<BaseException, Shift>> getShiftById(String id) async {
    try {
      final token = await AppSecureStorage().readToken();
      final response = await _dioHelper.getRequest(
        'api/v1/shifts/$id',
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
        return Left(DataException('Shift tidak ditemukan'));
      }

      return Right(ShiftModel.fromJson(res.data!));
    } catch (e) {
      return Left(NetworkException('Gagal mendapatkan template shift: $e'));
    }
  }

  @override
  Future<Either<BaseException, Shift>> createShift(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = {'auth_token': ?token, ...payload};

      final response = await _dioHelper.postRequest(
        'api/v1/shifts',
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
        return Left(DataException('Shift tidak ditemukan'));
      }

      final newShift = ShiftModel.fromJson(res.data!);
      return Right(newShift);
    } on DioException catch (e) {
      debugPrint('DioException on createShift: $e');
      return Left(NetworkException(e.response?.data));
    } catch (e, s) {
      debugPrint('Exception createShift: $e\n$s');
      return Left(DataException('Gagal membuat template shift'));
    }
  }

  @override
  Future<Either<BaseException, Shift>> updateShift(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = {'auth_token': ?token, '_method': 'PUT', ...payload};

      final response = await _dioHelper.postRequest(
        'api/v1/shifts/$id',
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
        return Left(DataException('Tidak dapat update shift'));
      }

      final updated = ShiftModel.fromJson(res.data!);
      return Right(updated);
    } catch (e) {
      return Left(DataException('Gagal memperbarui shift'));
    }
  }

  @override
  Future<Either<BaseException, Shift>> toggleShiftStatus(
    String id,
    bool isActive,
  ) async {
    return updateShift(id, {'is_active': isActive});
  }
}
