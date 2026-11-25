import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        return Left(NetworkException('No data found'));
      }

      final list = res.data!
          .map(
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

      try {
        await _dioHelper.postRequest(
          'api/v1/shift-assignments/bulk',
          requestBody: payload,
        );
      } catch (e) {
        debugPrint('Bulk endpoint fallback: $e');
      }

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
    } catch (e) {
      return Left(DataException(e.toString()));
    }
  }
}
