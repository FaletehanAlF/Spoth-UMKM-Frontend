import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_service.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(Dio());
});

class UploadResult {
  const UploadResult({required this.secureUrl, this.publicId});

  final String secureUrl;
  final String? publicId;
}

class UploadService {
  UploadService(this._client);

  final Dio _client;

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
    final formData = FormData.fromMap({
      'foto': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType ?? mimeTypeFor(filename)),
      ),
    });

    try {
      final response = await _client
          .postUri(
            Uri.parse('${AppConfig.baseUrl}/uploads/photo'),
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
            data: formData,
          )
          .timeout(_timeout);

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (jsonDecode(response.data.toString()) as Map<String, dynamic>);

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
    } on DioException catch (error) {
      if (error.response != null && (error.response!.statusCode ?? 0) >= 400) {
        throw const ApiException(
          statusCode: 0,
          message: 'Gagal mengunggah gambar. Silakan coba lagi.',
        );
      }

      throw const ApiException(
        statusCode: 0,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }
  }
}
