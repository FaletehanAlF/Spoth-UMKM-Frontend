import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_service.dart';

/// Provider global untuk [UploadService].
///
/// Dipisah agar mudah di-mock/override saat testing (sama seperti service lain).
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(http.Client());
});

/// Hasil sukses upload foto ke endpoint `POST /uploads/photo`.
class UploadResult {
  const UploadResult({required this.secureUrl, this.publicId});

  /// URL gambar yang sudah tersimpan di Cloudinary (dikirim ke backend).
  final String secureUrl;

  /// `public_id` gambar di Cloudinary (berguna bila kelak ada hapus foto).
  final String? publicId;
}

/// Akses ke endpoint upload foto backend SPOTH UMKM:
///
/// - `POST /api/uploads/photo` → butuh token HOST.
/// - Content-Type: multipart/form-data, field `foto` (satu file gambar).
/// - Format: JPG, JPEG, PNG, WEBP. Ukuran maksimal: 5 MB.
/// - Respons: `data: { secure_url, public_id }` (lihat `upload.controller.ts`).
///
/// Service ini sengaja tidak menyentuh [ApiService] inti karena endpoint-nya
/// memakai multipart/form-data, bukan JSON.
class UploadService {
  UploadService(this._client);

  final http.Client _client;

  /// Batas waktu maksimum untuk satu request upload (upload bisa lebih lama
  /// daripada request biasa).
  static const Duration _timeout = Duration(seconds: 60);

  /// Tipe konten yang diizinkan backend (harus konsisten dengan multer).
  static const Map<String, String> _mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
  };

  /// Menebak MIME type dari ekstensi nama file.
  static String mimeTypeFor(String filename) {
    final titik = filename.lastIndexOf('.');
    if (titik < 0) {
      return 'application/octet-stream';
    }
    return _mimeTypes[filename.substring(titik).toLowerCase()] ??
        'application/octet-stream';
  }

  /// Mengunggah satu foto tempat.
  ///
  /// Backend meneruskan file ke Cloudinary (file tidak disimpan backend),
  /// lalu mengembalikan `secure_url` untuk disimpan di data tempat.
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
