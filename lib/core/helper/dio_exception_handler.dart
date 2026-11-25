import 'package:dio/dio.dart';

class DioExceptionHandler {
  static String errorFromDio(DioException e) {
    return e.response?.data['error']?['message'] ?? 'Terjadi kesalahan server';
  }
}
