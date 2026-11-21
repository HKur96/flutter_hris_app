import 'package:equatable/equatable.dart';

class BaseResponse<T> extends Equatable {
  final bool success;
  final int status;
  final ApiError? error;
  final T? data;
  final Meta meta;

  const BaseResponse({
    required this.success,
    required this.status,
    this.data,
    required this.meta,
    this.error,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return BaseResponse<T>(
      success: json['success'] ?? false,
      status: json['status'] ?? 0,
      data: json['data'] != null
          ? (fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?)
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : Meta.empty(),
    );
  }

  @override
  List<Object?> get props => [success, status, error, data, meta];
}

class ApiError extends Equatable {
  final String code;
  final String message;
  final dynamic details;

  const ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'Terjadi kesalahan',
      details: json['details'],
    );
  }

  @override
  List<Object?> get props => [code, message, details];
}

class Meta extends Equatable {
  final DateTime timestamp;
  final String requestId;
  final String message;

  const Meta({
    required this.timestamp,
    required this.requestId,
    required this.message,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      requestId: json['requestId'] ?? '',
      message: json['message'] ?? '-',
    );
  }

  factory Meta.empty() {
    return Meta(timestamp: DateTime.now(), requestId: '', message: '-');
  }

  @override
  List<Object?> get props => [timestamp, requestId, message];
}
