import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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
