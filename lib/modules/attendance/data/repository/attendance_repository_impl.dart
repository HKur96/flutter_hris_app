import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hris_app/core/config/base_exception.dart';
import 'package:flutter_hris_app/core/config/base_response.dart';
import 'package:flutter_hris_app/core/helper/dio_exception_handler.dart';
import 'package:flutter_hris_app/core/helper/dio_helper.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:flutter_hris_app/core/utils/date_formatter.dart';
import 'package:flutter_hris_app/modules/attendance/data/model/attendance_model.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/domain/repository/attendance_repository.dart';
import 'package:fpdart/fpdart.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final DioHelper _dioHelper = DioHelper.instance;

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is String) {
      return jsonDecode(responseData) as Map<String, dynamic>;
    }
    return responseData as Map<String, dynamic>;
  }

  @override
  Future<Either<BaseException, Attendance?>> getTodayAttendance() async {
    try {
      final nowStr = DateFormatter.dateTimeToString(
        DateTime.now(),
        'yyyy-MM-dd',
      );
      final token = await AppSecureStorage().readToken();

      final response = await _dioHelper.getRequest(
        'api/v1/attendance',
        queryParameters: {
          'start_date': nowStr,
          'end_date': nowStr,
          'limit': 1,
          'auth_token': ?token,
        },
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<List<dynamic>>.fromJson(
        raw,
        fromJsonT: (items) => items as List<dynamic>,
      );

      if (baseRes.data != null && baseRes.data!.isNotEmpty) {
        final item = AttendanceModel.fromJson(
          baseRes.data!.first as Map<String, dynamic>,
        );
        return Right(item);
      }
      return const Right(null);
    } on DioException catch (e) {
      debugPrint('getTodayAttendance DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('getTodayAttendance Exception: $e');
      return Left(DataException('Gagal mengambil data presensi hari ini: $e'));
    }
  }

  @override
  Future<Either<BaseException, Attendance>> checkIn({
    required double lat,
    required double lng,
    bool? isMockLocation,
    bool? rejectMock,
    String? notes,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'auth_token': ?token,
        'is_mock_location': ?isMockLocation,
        'reject_mock': ?rejectMock,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await _dioHelper.postRequest(
        'api/v1/attendance/check-in',
        requestBody: body,
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<Map<String, dynamic>>.fromJson(
        raw,
        fromJsonT: (d) => d as Map<String, dynamic>,
      );

      if (baseRes.data != null) {
        return Right(AttendanceModel.fromJson(baseRes.data!));
      }
      return Left(DataException('Respon check-in tidak valid'));
    } on DioException catch (e) {
      debugPrint('checkIn DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('checkIn Exception: $e');
      return Left(DataException('Gagal melakukan check-in: $e'));
    }
  }

  @override
  Future<Either<BaseException, Attendance>> checkOut({
    required double lat,
    required double lng,
    String? notes,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'auth_token': ?token,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await _dioHelper.postRequest(
        'api/v1/attendance/check-out',
        requestBody: body,
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<Map<String, dynamic>>.fromJson(
        raw,
        fromJsonT: (d) => d as Map<String, dynamic>,
      );

      if (baseRes.data != null) {
        return Right(AttendanceModel.fromJson(baseRes.data!));
      }
      return Left(DataException('Respon check-out tidak valid'));
    } on DioException catch (e) {
      debugPrint('checkOut DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('checkOut Exception: $e');
      return Left(DataException('Gagal melakukan check-out: $e'));
    }
  }

  @override
  Future<Either<BaseException, List<Attendance>>> getAttendanceList({
    String? employeeId,
    String? shiftId,
    String? status,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final queryParams = <String, dynamic>{
        'auth_token': ?token,
        if (employeeId != null && employeeId.isNotEmpty)
          'employee_id': employeeId,
        if (shiftId != null && shiftId.isNotEmpty) 'shift_id': shiftId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        'limit': ?limit,
        'offset': ?offset,
      };

      final response = await _dioHelper.getRequest(
        'api/v1/attendance',
        queryParameters: queryParams,
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<List<dynamic>>.fromJson(
        raw,
        fromJsonT: (items) => items as List<dynamic>,
      );

      if (baseRes.data != null) {
        final list = baseRes.data!
            .map<Attendance>(
              (item) => AttendanceModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        return Right(list);
      }
      return const Right([]);
    } on DioException catch (e) {
      debugPrint('getAttendanceList DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('getAttendanceList Exception: $e');
      return Left(DataException('Gagal memuat daftar presensi: $e'));
    }
  }

  @override
  Future<Either<BaseException, Attendance>> getAttendanceDetail(
    String id,
  ) async {
    try {
      final token = await AppSecureStorage().readToken();
      final response = await _dioHelper.getRequest(
        'api/v1/attendance/$id',
        queryParameters: {'auth_token': ?token},
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<Map<String, dynamic>>.fromJson(
        raw,
        fromJsonT: (d) => d as Map<String, dynamic>,
      );

      if (baseRes.data != null) {
        return Right(AttendanceModel.fromJson(baseRes.data!));
      }
      return Left(DataException('Detail presensi tidak ditemukan'));
    } on DioException catch (e) {
      debugPrint('getAttendanceDetail DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('getAttendanceDetail Exception: $e');
      return Left(DataException('Gagal memuat detail presensi: $e'));
    }
  }

  @override
  Future<Either<BaseException, Attendance>> createManualAttendance({
    required String employeeId,
    required String workDate,
    required String shiftId,
    required String status,
    required String notes,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = <String, dynamic>{
        'employee_id': employeeId,
        'work_date': workDate,
        'shift_id': shiftId,
        'status': status,
        'notes': notes,
        'auth_token': ?token,
      };

      final response = await _dioHelper.postRequest(
        'api/v1/attendance',
        requestBody: body,
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<Map<String, dynamic>>.fromJson(
        raw,
        fromJsonT: (d) => d as Map<String, dynamic>,
      );

      if (baseRes.data != null) {
        return Right(AttendanceModel.fromJson(baseRes.data!));
      }
      return Left(DataException('Respon presensi manual tidak valid'));
    } on DioException catch (e) {
      debugPrint('createManualAttendance DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('createManualAttendance Exception: $e');
      return Left(DataException('Gagal membuat presensi manual: $e'));
    }
  }

  @override
  Future<Either<BaseException, Attendance>> adjustAttendance({
    required String id,
    required String status,
    required String notes,
  }) async {
    try {
      final token = await AppSecureStorage().readToken();
      final body = <String, dynamic>{
        '_method': 'PUT',
        'status': status,
        'notes': notes,
        'auth_token': ?token,
      };

      final response = await _dioHelper.postRequest(
        'api/v1/attendance/$id',
        requestBody: body,
      );

      final raw = _extractData(response.data);
      final baseRes = BaseResponse<Map<String, dynamic>>.fromJson(
        raw,
        fromJsonT: (d) => d as Map<String, dynamic>,
      );

      if (baseRes.data != null) {
        return Right(AttendanceModel.fromJson(baseRes.data!));
      }
      return Left(DataException('Respon koreksi presensi tidak valid'));
    } on DioException catch (e) {
      debugPrint('adjustAttendance DioException: $e');
      return Left(NetworkException(DioExceptionHandler.errorFromDio(e)));
    } catch (e) {
      debugPrint('adjustAttendance Exception: $e');
      return Left(DataException('Gagal mengoreksi data presensi: $e'));
    }
  }
}
