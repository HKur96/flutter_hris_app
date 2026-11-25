import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hris_app/core/helper/dio_exception_handler.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/base_exception.dart';
import '../../../../core/config/base_response.dart';
import '../../../../core/helper/dio_helper.dart';
import '../../../../core/shared/app_secure_storage.dart';
import '../../domain/entity/shift_assignment.dart';
import '../../domain/repository/shift_assignment_repository.dart';
import '../model/shift_assignment_model.dart';

/// Implementasi Repository Penugasan Shift (GAS Modul 4)
/// Dilengkapi dataset lokal tangguh (Resilience Offline/Demo) sesuai Stitch Mockup 01-10.
class ShiftAssignmentRepositoryImpl implements ShiftAssignmentRepository {
  final DioHelper _dioHelper = DioHelper.instance;

  @override
  Future<Either<BaseException, List<ShiftAssignment>>> getShiftAssignments({
    String? employeeId,
    String? shiftId,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final queryParams = <String, dynamic>{
        'auth_token': ?token,
        'employee_id': ?employeeId,
        'shift_id': ?shiftId,
        'start_date': ?startDate,
        'end_date': ?endDate,
        'limit': ?limit,
        'offset': ?offset,
      };

      final response = await _dioHelper.getRequest(
        'api/v1/shift-assignments',
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
          .map<ShiftAssignment>(
            (item) =>
                ShiftAssignmentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return Right(list);
    } on DioException catch (e) {
      debugPrint('DioException on getShiftAssignments: $e');
      return Left(NetworkException(e.message ?? 'Network error'));
    } catch (e) {
      debugPrint('Exception on getShiftAssignments: $e');
      return Left(DataException(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final payload = {
        'auth_token': token,
        'shift_id': shiftId,
        'start_date': startDate,
        'end_date': endDate,
        'employee_ids': employeeIds,
      };

      // Hitung rentang hari secara inklusif
      final startDt = DateTime.tryParse(startDate) ?? DateTime.now();
      final endDt = DateTime.tryParse(endDate) ?? DateTime.now();
      final totalDays = endDt.difference(startDt).inDays + 1;
      final safeDays = totalDays > 0 ? totalDays : 1;
      final count = safeDays * employeeIds.length;

      await _dioHelper.postRequest(
        'api/v1/shift-assignments/bulk',
        requestBody: payload,
      );

      return Right(
        BulkAssignmentResult(
          count: count,
          totalDays: safeDays,
          totalEmployees: employeeIds.length,
          employeeNames: employeeNames ?? [],
          startDate: startDate,
          endDate: endDate,
          shiftName: shiftName ?? 'Shift Terpilih',
        ),
      );
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      return Left(DataException(e.toString()));
    }
  }

  @override
  Future<Either<BaseException, ShiftAssignment>> updateShiftAssignment({
    required String id,
    required String shiftId,
    String? workDate,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final payload = <String, dynamic>{
        'auth_token': token,
        '_method': 'PUT',
        'shift_id': shiftId,
        'work_date': ?workDate,
      };

      final response = await _dioHelper.putRequest(
        'api/v1/shift-assignments/$id',
        requestBody: payload,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      if (res.data == null) {
        return Left(DataException('Data penugasan shift kosong'));
      }

      final item = ShiftAssignmentModel.fromJson(res.data!);
      return Right(item);
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      return Left(DataException(e.toString()));
    }
  }

  @override
  Future<Either<BaseException, String>> deleteShiftAssignment(String id) async {
    try {
      final token = await AppSecureStorage().readToken();
      final payload = <String, dynamic>{
        'auth_token': token,
        '_method': 'DELETE',
      };

      final response = await _dioHelper.deleteRequest(
        'api/v1/shift-assignments/$id',
        requestBody: payload,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      final deletedId = res.data?['id']?.toString() ?? id;
      return Right(deletedId);
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      return Left(DataException(e.toString()));
    }
  }

  @override
  Future<Either<BaseException, BulkUpdateResult>> updateBulkAssignment({
    required String shiftId,
    List<String>? assignmentIds,
    String? startDate,
    String? endDate,
    List<String>? employeeIds,
    String? oldShiftId,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final payload = <String, dynamic>{
        'auth_token': token,
        '_method': 'PUT',
        'shift_id': shiftId,
        'assignment_ids': ?assignmentIds,
        'start_date': ?startDate,
        'end_date': ?endDate,
        'employee_ids': ?employeeIds,
        'old_shift_id': ?oldShiftId,
      };

      final response = await _dioHelper.putRequest(
        'api/v1/shift-assignments/bulk',
        requestBody: payload,
      );

      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final res = BaseResponse<Map<String, dynamic>>.fromJson(
        raw as Map<String, dynamic>,
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      final data = res.data ?? {};
      final count = (data['count'] as num?)?.toInt() ??
          (assignmentIds?.length ?? 0);
      final rawUpdatedIds = data['updated_ids'] as List<dynamic>? ?? [];
      final updatedIds = rawUpdatedIds.map((e) => e.toString()).toList();
      final newShiftId = data['new_shift_id']?.toString() ?? shiftId;
      final newShiftName = data['new_shift_name']?.toString();

      return Right(
        BulkUpdateResult(
          count: count,
          updatedIds: updatedIds,
          newShiftId: newShiftId,
          newShiftName: newShiftName,
        ),
      );
    } on DioException catch (e) {
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      return Left(DataException(e.toString()));
    }
  }
}
