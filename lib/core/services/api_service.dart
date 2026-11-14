import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Provider global untuk [ApiService].
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Error dari REST API backend.
///
/// Backend selalu mengirim body `{ success: false, message: "..." }`
/// dan pada error validasi (HTTP 400) juga disertai field `errors`
/// berisi daftar `{ field, message }`.
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

/// Pembungkus sederhana package `http` untuk memanggil REST API backend.
///
/// Token JWT (jika diperlukan) dikirim lewat parameter `token` dan
/// dipasang pada header `Authorization: Bearer <token>`.
///
/// Method melempar [ApiException] bila status HTTP >= 400 sehingga
/// pemanggil bisa membedakan error validasi (400), autentikasi (401),
/// konflik (409), dan rate limit (429). Request yang melebihi [timeout]
/// (default 15 detik) melempar [ApiException] dengan status 408.
class ApiService {
  ApiService({http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Batas waktu maksimum untuk setiap request HTTP.
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
      } catch (_) {
        // Body bukan JSON valid; biarkan kosong dan ditangani di bawah.
      }
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

  /// Menjalankan [request] dengan batas waktu [timeout].
  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message:
            'Permintaan melebihi batas waktu. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final response = await _withTimeout(
      _client.get(_uri(path), headers: _headers(token: token)),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _withTimeout(
      _client.post(
        _uri(path),
        headers: _headers(token: token),
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _withTimeout(
      _client.patch(
        _uri(path),
        headers: _headers(token: token),
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) async {
    final response = await _withTimeout(
      _client.delete(_uri(path), headers: _headers(token: token)),
    );
    return _handleResponse(response);
  }
}
