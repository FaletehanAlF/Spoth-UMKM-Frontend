import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  ApiService({http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  final http.Client _client;

  final Duration timeout;

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = <String, dynamic>{};

    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            (body['message'] as String?) ?? 'Terjadi kesalahan pada server',
        errors: body['errors'] as List<dynamic>?,
      );
    }

    return body;
  }

  /// Pembungkus semua request HTTP (pola dari dokumentasi guru:
  /// try-catch `TimeoutException` + `ClientException`).
  ///
  /// `http.ClientException` dipakai (bukan `SocketException`) supaya kode
  /// tetap bisa di-compile ke Flutter Web — `dart:io` tidak tersedia di web.
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message:
            'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.',
      );
    } on http.ClientException {
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
      () => _client.get(_uri(path), headers: _headers(token: token)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(
      () => _client.post(
        _uri(path),
        headers: _headers(token: token),
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(
      () => _client.patch(
        _uri(path),
        headers: _headers(token: token),
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return _send(
      () => _client.delete(_uri(path), headers: _headers(token: token)),
    );
  }

  /// Menutup koneksi HTTP saat provider di-dispose (hindari kebocoran).
  void close() => _client.close();
}
