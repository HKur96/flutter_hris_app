import 'dart:convert';
import 'dart:developer' as logger;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:requests_inspector/requests_inspector.dart';

class DioHelper {
  static DioHelper? _instance;
  final Dio dio;

  // Konstruktor privat
  DioHelper._internal({Duration? connectTimeout, Duration? receiveTimeout})
    : dio = Dio(
        BaseOptions(
          connectTimeout: connectTimeout ?? const Duration(seconds: 60),
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
          followRedirects: true,
        ),
      ) {
    dio.interceptors.addAll([
      _DioLoggingInterceptor(),
      _GoogleAppsScriptRedirectInterceptor(dio),
      RequestsInspectorInterceptor(),
    ]);
  }

  // Factory constructor untuk mengembalikan satu instance yang sama
  factory DioHelper({Duration? connectTimeout, Duration? receiveTimeout}) {
    _instance ??= DioHelper._internal(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return _instance!;
  }

  // Getter opsional agar bisa dipanggil dengan DioHelper.instance
  static DioHelper get instance => DioHelper();

  String _baseUrl = '';
  set baseUrl(String baseUrl) => _baseUrl = baseUrl;

  Future<Response> postRequest(
    String path, {
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.post(
        _baseUrl,
        data: requestBody,
        queryParameters: {'path': path, ...?queryParameters},
      );

      if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
        throw DioException(requestOptions: res.requestOptions);
      }

      return res;
    } on DioException catch (e) {
      _printLog('$e');
      rethrow;
    }
  }

  Future<Response> getRequest(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await dio.get(
        _baseUrl,
        queryParameters: {'path': path, ...?queryParameters},
        data: body,
      );

      if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
        throw DioException(requestOptions: res.requestOptions);
      }

      return res;
    } on DioException catch (e) {
      _printLog('$e');
      rethrow;
    }
  }

  Future<Response> patchRequest(
    String path, {
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.patch(
        _baseUrl,
        data: requestBody,
        queryParameters: {'path': path, ...?queryParameters},
      );

      if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
        throw DioException(requestOptions: res.requestOptions);
      }

      return res;
    } on DioException catch (e) {
      _printLog('$e');
      rethrow;
    }
  }

  Future<Response> putRequest(
    String path, {
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.put(
        _baseUrl,
        data: requestBody,
        queryParameters: {'path': path, ...?queryParameters},
      );

      if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
        throw DioException(requestOptions: res.requestOptions);
      }

      return res;
    } on DioException catch (e) {
      _printLog('$e');
      rethrow;
    }
  }

  Future<Response> postFormRequest(
    String path, {
    Object? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.post(
        _baseUrl,
        data: requestBody,
        queryParameters: {'path': path, ...?queryParameters},
      );

      return res;
    } on DioException catch (e) {
      _printLog('$e');
      rethrow;
    }
  }

  void _printLog(String message) {
    if (kDebugMode) {
      logger.log(message, name: 'dio');
    }
  }
}

/// Interceptor untuk mencetak log Request, Payload / Body, QueryParams, dan Response secara jelas di console
class _DioLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && options.extra['is_redirect_fetch'] != true) {
      final buffer = StringBuffer();
      buffer.writeln('┌─────────────────────────────────────────────────────────────');
      buffer.writeln('│ 🚀 [DIO REQUEST] ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ 🔍 QueryParams: ${options.queryParameters}');
      }
      if (options.data != null) {
        buffer.writeln('│ 📦 Payload / Body: ${_formatPayload(options.data)}');
      }
      buffer.write('└─────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode && response.requestOptions.extra['is_redirect_fetch'] != true) {
      final buffer = StringBuffer();
      buffer.writeln('┌─────────────────────────────────────────────────────────────');
      buffer.writeln('│ ✅ [DIO RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      if (response.requestOptions.data != null) {
        buffer.writeln('│ 📦 Sent Payload: ${_formatPayload(response.requestOptions.data)}');
      }
      buffer.writeln('│ 📥 Response Body: ${response.data}');
      buffer.write('└─────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && err.requestOptions.extra['is_redirect_fetch'] != true) {
      final buffer = StringBuffer();
      buffer.writeln('┌─────────────────────────────────────────────────────────────');
      buffer.writeln('│ ❌ [DIO ERROR] ${err.response?.statusCode ?? 'ERROR'} ${err.requestOptions.uri}');
      if (err.requestOptions.data != null) {
        buffer.writeln('│ 📦 Sent Payload: ${_formatPayload(err.requestOptions.data)}');
      }
      buffer.writeln('│ ⚠️ Error: ${err.message}');
      if (err.response?.data != null) {
        buffer.writeln('│ 📥 Error Body: ${err.response?.data}');
      }
      buffer.write('└─────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    }
    handler.next(err);
  }

  String _formatPayload(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}

/// Interceptor khusus untuk mengikuti redirect HTTP 302 dari Google Apps Script Web App.
/// GAS mengarahkan setiap request POST dengan status 302 menuju URL `script.googleusercontent.com`
/// yang harus diambil menggunakan metode GET untuk memperoleh body response sesungguhnya.
class _GoogleAppsScriptRedirectInterceptor extends Interceptor {
  final Dio _dio;

  _GoogleAppsScriptRedirectInterceptor(this._dio);

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isRedirectStatus(response.statusCode)) {
      final location = response.headers.value('location');
      if (location != null && location.isNotEmpty) {
        try {
          final originalOptions = response.requestOptions;
          final redirectedResponse = await _dio.get(
            location,
            options: Options(
              responseType: originalOptions.responseType,
              extra: {'is_redirect_fetch': true},
            ),
          );
          // Pertahankan RequestOptions dan Payload asli agar tercatat di Logger & RequestsInspector
          redirectedResponse.requestOptions = originalOptions;
          return handler.resolve(redirectedResponse);
        } catch (e) {
          return handler.next(response);
        }
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response != null && _isRedirectStatus(response.statusCode)) {
      final location = response.headers.value('location');
      if (location != null && location.isNotEmpty) {
        try {
          final originalOptions = response.requestOptions;
          final redirectedResponse = await _dio.get(
            location,
            options: Options(
              responseType: originalOptions.responseType,
              extra: {'is_redirect_fetch': true},
            ),
          );
          // Pertahankan RequestOptions dan Payload asli agar tercatat di Logger & RequestsInspector
          redirectedResponse.requestOptions = originalOptions;
          return handler.resolve(redirectedResponse);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }

  bool _isRedirectStatus(int? statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }
}
