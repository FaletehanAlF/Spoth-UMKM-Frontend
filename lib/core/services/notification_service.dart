import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import 'api_service.dart';

/// Provider global untuk [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiServiceProvider));
});

/// Akses ke endpoint notifikasi backend SPOTH UMKM (semuanya butuh token):
///
/// - `GET   /notifications`          → daftar notifikasi milik pengguna
/// - `GET   /notifications/summary`  → ringkasan `{ total, belum_dibaca }`
/// - `PATCH /notifications/:id/read` → tandai satu sudah dibaca
/// - `POST  /notifications/read-all` → tandai semua sudah dibaca
///
/// Isi notifikasi dibuat otomatis oleh backend saat pemesanan/pembayaran
/// terjadi — frontend tidak pernah membuat notifikasi palsu.
class NotificationService {
  NotificationService(this._apiService);

  final ApiService _apiService;

  String _query(Map<String, String?> params) {
    final entries = <String, String>{};
    params.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        entries[key] = value;
      }
    });

    final query = Uri(queryParameters: entries).query;
    return query.isEmpty ? '' : '?$query';
  }

  /// Daftar notifikasi milik pengguna yang sedang login.
  Future<List<NotificationModel>> list({
    required String token,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    final body = await _apiService.get(
      '/notifications${_query({'unread_only': unreadOnly ? 'true' : null, 'page': '1', 'limit': '$limit'})}',
      token: token,
    );

    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>?;

    if (items == null) {
      throw const FormatException('Respons daftar notifikasi tidak valid');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  /// Ringkasan jumlah notifikasi total dan belum dibaca (untuk badge).
  Future<NotificationSummaryModel> summary({required String token}) async {
    final body = await _apiService.get('/notifications/summary', token: token);
    final data = body['data'] as Map<String, dynamic>?;
    final ringkasan = data?['ringkasan'] as Map<String, dynamic>?;

    if (ringkasan == null) {
      throw const FormatException('Respons ringkasan notifikasi tidak valid');
    }

    return NotificationSummaryModel.fromJson(ringkasan);
  }

  /// Menandai satu notifikasi sebagai sudah dibaca.
  Future<void> markRead({required String token, required String id}) async {
    await _apiService.patch('/notifications/$id/read', {}, token: token);
  }

  /// Menandai semua notifikasi sebagai sudah dibaca.
  Future<void> markAllRead({required String token}) async {
    await _apiService.post('/notifications/read-all', {}, token: token);
  }
}
