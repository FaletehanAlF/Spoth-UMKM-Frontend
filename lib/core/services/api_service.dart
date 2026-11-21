import 'dart:convert';

import 'package:dio/dio.dart';
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

class ApiService {
  ApiService({Dio? dio, this.timeout = const Duration(seconds: 15)})
    : _client = dio ?? Dio();

  final Dio _client;

  final Duration timeout;

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    Map<String, dynamic> body = <String, dynamic>{};

    if (data is Map<String, dynamic>) {
      body = data;
    } else if (data != null && data.toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(data.toString());
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {}
    }

    if (statusCode >= 400) {
      throw ApiException(
        statusCode: statusCode,
        message:
            (body['message'] as String?) ?? 'Terjadi kesalahan pada server',
        errors: body['errors'] as List<dynamic>?,
      );
    }

    return body;
  }

  /// Pembungkus semua request HTTP menggunakan Dio.
  ///
  /// Semua kondisi jaringan ditangkap menjadi [ApiException] agar service
  /// lain dapat menangani kesalahan jaringan secara konsisten.
  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      if (error.response != null) {
        final data = error.response!.data;
        final message = data is Map<String, dynamic>
            ? (data['message'] as String?) ??
                error.message ??
                'Terjadi kesalahan pada server'
            : error.message ?? 'Terjadi kesalahan pada server';
        throw ApiException(
          statusCode: error.response!.statusCode ?? 0,
          message: message,
          errors: null,
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.transformTimeout) {
        throw const ApiException(
          statusCode: 408,
          message:
              'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.',
        );
      }

      throw const ApiException(
        statusCode: 0,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        message: 'Terjadi kesalahan jaringan: $error',
      );
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _send(
      () => _client.getUri(
        _uri(path),
        options: Options(headers: _headers(token: token)),
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(
      () => _client.postUri(
        _uri(path),
        options: Options(headers: _headers(token: token)),
        data: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(
      () => _client.patchUri(
        _uri(path),
        options: Options(headers: _headers(token: token)),
        data: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return _send(
      () => _client.deleteUri(
        _uri(path),
        options: Options(headers: _headers(token: token)),
      ),
    );
  }

  /// Menutup koneksi saat provider di-dispose (hindari kebocoran).
  void close({bool force = true}) => _client.close(force: force);
}
