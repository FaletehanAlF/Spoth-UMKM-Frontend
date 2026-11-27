import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(service.close);
  return service;
});

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int statusCode;
  final String message;
  final List<dynamic>? errors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Interface HTTP tunggal untuk layanan API.
///
/// Semua request ditangkap menjadi [ApiException] supaya call site
/// mudah dimengerti: timeout -> 408, koneksi gagal -> 0.
class ApiService {
  ApiService({Dio? dio, this.timeout = const Duration(seconds: 15)})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final Duration timeout;

  /// Buat URI lengkap dari path API.
  Uri uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> headers({String? token}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Mulai satu request lewat [request].
  ///
  /// Return value: body response berbentuk map JSON.
  Future<Map<String, dynamic>> send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      return _parseBody(response);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _toApiException(error);
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Terjadi kesalahan jaringan: $error',
      );
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return send(
      () => _dio.getUri(uri(path), options: _options(token)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return send(
      () => _dio.postUri(
        uri(path),
        options: _options(token),
        data: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return send(
      () => _dio.patchUri(
        uri(path),
        options: _options(token),
        data: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return send(() => _dio.deleteUri(uri(path), options: _options(token)));
  }

  Options _options(String? token) => Options(headers: headers(token: token));

  Map<String, dynamic> _parseBody(Response<dynamic> response) {
    return _asMap(response.data);
  }

  ApiException _toApiException(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      final body = _asMap(error.response!.data);
      return ApiException(
        statusCode: statusCode,
        message:
            (body['message'] as String?) ??
            error.message ??
            'Terjadi kesalahan pada server',
        errors: body['errors'] as List<dynamic>?,
      );
    }

    // Membantu saat tes di HP: alamat yang dituju ikut tampil di console.
    debugPrint(
      '[api] ${error.requestOptions.uri} -> ${error.type}: ${error.message}',
    );

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.transformTimeout) {
      return const ApiException(
        statusCode: 408,
        message:
            'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.',
      );
    }

    return const ApiException(
      statusCode: 0,
      message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    try {
      final decoded = jsonDecode(value.toString());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  void close({bool force = true}) => _dio.close(force: force);
}
