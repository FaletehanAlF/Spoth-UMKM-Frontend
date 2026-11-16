import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_service.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(http.Client());
});

class UploadResult {
  const UploadResult({required this.secureUrl, this.publicId});

  final String secureUrl;

  final String? publicId;
}

class UploadService {
  UploadService(this._client);

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 60);

  static const Map<String, String> _mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
  };

  static String mimeTypeFor(String filename) {
    final titik = filename.lastIndexOf('.');
    if (titik < 0) {
      return 'application/octet-stream';
    }
    return _mimeTypes[filename.substring(titik).toLowerCase()] ??
        'application/octet-stream';
  }

  Future<UploadResult> uploadPhoto({
    required String token,
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${AppConfig.baseUrl}/uploads/photo'),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          });

    request.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: filename,
        contentType: http.MediaType.parse(mimeType ?? mimeTypeFor(filename)),
      ),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Upload melebihi batas waktu. Periksa koneksi internet Anda.',
      );
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    final response = await http.Response.fromStream(streamed);

    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = <String, dynamic>{};
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: (body['message'] as String?) ?? 'Gagal mengunggah gambar',
        errors: body['errors'] as List<dynamic>?,
      );
    }

    final data = body['data'];
    final secureUrl = data is Map<String, dynamic>
        ? data['secure_url'] as String?
        : null;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw const FormatException('Respons upload tidak berisi secure_url');
    }

    return UploadResult(
      secureUrl: secureUrl,
      publicId: data is Map<String, dynamic>
          ? data['public_id'] as String?
          : null,
    );
  }
}
