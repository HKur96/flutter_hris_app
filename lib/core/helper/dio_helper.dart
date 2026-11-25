import 'dart:convert';
import 'dart:developer' as logger;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/core/shared/app_secure_storage.dart';
import 'package:requests_inspector/requests_inspector.dart';

/// Helper HTTP Client menggunakan Dio untuk Cloudflare Workers + Turso Backend.
/// Mendukung REST Verbs native, bearer token otomatis, silent refresh token pada 401,
/// force logout pada 403 (ACCOUNT_DEACTIVATED), dan logging debug.
class DioHelper {
  static DioHelper? _instance;
  final Dio dio;

  String _baseUrl = const String.fromEnvironment(
    'base_url',
    defaultValue: 'https://hris-backend-worker.hkurhris.workers.dev/',
  );

  // Konstruktor privat
  DioHelper._internal({Duration? connectTimeout, Duration? receiveTimeout})
    : dio = Dio(
        BaseOptions(
          connectTimeout: connectTimeout ?? const Duration(seconds: 30),
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          followRedirects: true,
        ),
      ) {
    dio.options.baseUrl = _baseUrl;
    dio.interceptors.addAll([
      _AuthInterceptor(this),
      _DioLoggingInterceptor(),
      RequestsInspectorInterceptor(),
    ]);
  }

  // Factory constructor untuk mengembalikan satu instance singleton
  factory DioHelper({Duration? connectTimeout, Duration? receiveTimeout}) {
    _instance ??= DioHelper._internal(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return _instance!;
  }

  // Getter static agar bisa dipanggil dengan DioHelper.instance
  static DioHelper get instance => DioHelper();

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    _baseUrl = url;
    dio.options.baseUrl = _baseUrl;
  }

  /// Menormalisasi penggabungan base URL dan endpoint path agar tidak terjadi
  /// duplikasi slash (//) ataupun hilangnya slash pemisah.
  String _buildUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }

  Future<Response> postRequest(
    String path, {
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.post(
        _buildUrl(path),
        data: requestBody,
        queryParameters: {...?queryParameters},
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
        _buildUrl(path),
        queryParameters: {...?queryParameters},
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
        _buildUrl(path),
        data: requestBody,
        queryParameters: {...?queryParameters},
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
        _buildUrl(path),
        data: requestBody,
        queryParameters: {...?queryParameters},
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

  Future<Response> deleteRequest(
    String path, {
    Map<String, dynamic>? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.delete(
        _buildUrl(path),
        data: requestBody,
        queryParameters: {...?queryParameters},
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
        _buildUrl(path),
        data: requestBody,
        queryParameters: {...?queryParameters},
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

/// Interceptor cerdas untuk:
/// 1. Menambahkan Bearer Token secara otomatis di setiap request.
/// 2. Menangani HTTP 401 Unauthorized dengan Silent Refresh Token & Auto Retry.
/// 3. Menangani HTTP 403 Forbidden dengan kode ACCOUNT_DEACTIVATED untuk Force Logout.
class _AuthInterceptor extends QueuedInterceptor {
  final DioHelper _dioHelper;
  static bool _isLoggingOut = false;

  _AuthInterceptor(this._dioHelper);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Otomatis inject Bearer token jika belum ada di header dan user sudah login
    if (!options.headers.containsKey('Authorization')) {
      final token = await AppSecureStorage().readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final statusCode = response?.statusCode;

    // 1. Penanganan 403 Forbidden: Cek apakah akun dinonaktifkan (ACCOUNT_DEACTIVATED)
    if (statusCode == 403) {
      if (_isAccountDeactivated(response?.data)) {
        await _handleForceLogout(
          message: 'Akun Anda telah dinonaktifkan oleh administrator.',
        );
        return handler.next(err);
      }
      // Jika 403 biasa (misal batas hak akses / RBAC / self-boundary), teruskan error ke UI tanpa logout
      return handler.next(err);
    }

    // 2. Penanganan 401 Unauthorized: Refresh Access Token
    if (statusCode == 401) {
      final requestPath = err.requestOptions.path;

      // Cegah loop refresh jika request yang gagal memang endpoint autentikasi
      if (requestPath.contains('auth/login') ||
          requestPath.contains('auth/refresh') ||
          requestPath.contains('auth/setup-owner')) {
        // Jika endpoint refresh yang menghasilkan 401 (INVALID_REFRESH_TOKEN), bersihkan sesi
        if (requestPath.contains('auth/refresh')) {
          await _handleForceLogout(
            message: 'Sesi login telah berakhir. Silakan masuk kembali.',
          );
        }
        return handler.next(err);
      }

      final refreshToken = await AppSecureStorage().readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _handleForceLogout(
          message: 'Sesi login telah berakhir. Silakan masuk kembali.',
        );
        return handler.next(err);
      }

      try {
        // Instance Dio khusus terisolasi tanpa interceptor bertumpuk untuk refresh token
        final refreshDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final refreshUrl = _dioHelper._buildUrl('api/v1/auth/refresh');
        final refreshResponse = await refreshDio.post(
          refreshUrl,
          data: {'refresh_token': refreshToken},
        );

        if (refreshResponse.statusCode == 200) {
          final dynamic rawData = refreshResponse.data is String
              ? jsonDecode(refreshResponse.data as String)
              : refreshResponse.data;

          final data = rawData is Map<String, dynamic>
              ? (rawData['data'] as Map<String, dynamic>?)
              : null;

          final newAccessToken = data?['token'] ?? data?['access_token'];
          final newRefreshToken = data?['refresh_token'];

          if (newAccessToken != null) {
            await AppSecureStorage().writeToken(newAccessToken.toString());
          }
          if (newRefreshToken != null) {
            await AppSecureStorage().writeRefreshToken(
              newRefreshToken.toString(),
            );
          }

          // Perbarui header Authorization pada request asli yang gagal
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          // Perbarui parameter token legacy jika request menyertakannya
          if (err.requestOptions.queryParameters.containsKey('auth_token')) {
            err.requestOptions.queryParameters['auth_token'] = newAccessToken;
          }
          if (err.requestOptions.data is Map &&
              (err.requestOptions.data as Map).containsKey('auth_token')) {
            (err.requestOptions.data as Map)['auth_token'] = newAccessToken;
          }

          // Ulangi (retry) request asli menggunakan Dio utama
          final retryResponse = await _dioHelper.dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } else {
          await _handleForceLogout(
            message: 'Sesi login telah berakhir. Silakan masuk kembali.',
          );
          return handler.next(err);
        }
      } on DioException catch (refreshErr) {
        // Jika saat refresh akun terdeteksi nonaktif (403 ACCOUNT_DEACTIVATED)
        if (refreshErr.response?.statusCode == 403 &&
            _isAccountDeactivated(refreshErr.response?.data)) {
          await _handleForceLogout(
            message: 'Akun Anda telah dinonaktifkan oleh administrator.',
          );
        } else {
          await _handleForceLogout(
            message: 'Sesi login telah berakhir. Silakan masuk kembali.',
          );
        }
        return handler.next(err);
      } catch (_) {
        await _handleForceLogout(
          message: 'Sesi login telah berakhir. Silakan masuk kembali.',
        );
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _isAccountDeactivated(dynamic responseData) {
    if (responseData == null) return false;
    try {
      dynamic data = responseData;
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is Map) {
        final error = data['error'];
        if (error is Map) {
          final code = error['code']?.toString();
          if (code == 'ACCOUNT_DEACTIVATED') return true;
        }
        final code = data['code']?.toString();
        if (code == 'ACCOUNT_DEACTIVATED') return true;
        final message = (data['message'] ?? error?['message'])
            ?.toString()
            .toLowerCase() ??
            '';
        if (message.contains('deactivated') ||
            message.contains('dinonaktifkan')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _handleForceLogout({required String message}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      await AppSecureStorage().clearAll();

      final context = gNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      gNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppConstants.kRouteLogin,
        (route) => false,
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
}

/// Interceptor untuk mencetak log Request, Payload / Body, QueryParams, dan Response secara rapi di console
class _DioLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌─────────────────────────────────────────────────────────────',
      );
      buffer.writeln('│ 🚀 [DIO REQUEST] ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ 🔍 QueryParams: ${options.queryParameters}');
      }
      if (options.headers.isNotEmpty) {
        buffer.writeln('│ 📋 Headers: ${options.headers}');
      }
      if (options.data != null) {
        buffer.writeln('│ 📦 Payload / Body: ${_formatPayload(options.data)}');
      }
      buffer.write(
        '└─────────────────────────────────────────────────────────────',
      );
      debugPrint(buffer.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌─────────────────────────────────────────────────────────────',
      );
      buffer.writeln(
        '│ ✅ [DIO RESPONSE] ${response.statusCode} ${response.requestOptions.uri}',
      );
      if (response.requestOptions.data != null) {
        buffer.writeln(
          '│ 📦 Sent Payload: ${_formatPayload(response.requestOptions.data)}',
        );
      }
      buffer.writeln('│ 📥 Response Body: ${response.data}');
      buffer.write(
        '└─────────────────────────────────────────────────────────────',
      );
      debugPrint(buffer.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln(
        '┌─────────────────────────────────────────────────────────────',
      );
      buffer.writeln(
        '│ ❌ [DIO ERROR] ${err.response?.statusCode ?? 'ERROR'} ${err.requestOptions.uri}',
      );
      if (err.requestOptions.data != null) {
        buffer.writeln(
          '│ 📦 Sent Payload: ${_formatPayload(err.requestOptions.data)}',
        );
      }
      buffer.writeln('│ ⚠️ Error: ${err.message}');
      if (err.response?.data != null) {
        buffer.writeln('│ 📥 Error Body: ${err.response?.data}');
      }
      buffer.write(
        '└─────────────────────────────────────────────────────────────',
      );
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
