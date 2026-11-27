import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import 'api_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiServiceProvider));
});

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

  Future<List<NotificationModel>> list({
    required String token,
    bool unreadOnly = false,
    int page = 1,
    int limit = 50,
  }) async {
    final body = await _apiService.get(
      '/notifications${_query({'unread_only': unreadOnly ? 'true' : null, 'page': '$page', 'limit': '$limit'})}',
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

  Future<NotificationSummaryModel> summary({required String token}) async {
    final body = await _apiService.get('/notifications/summary', token: token);
    final data = body['data'] as Map<String, dynamic>?;
    final ringkasan = data?['ringkasan'] as Map<String, dynamic>?;

    if (ringkasan == null) {
      throw const FormatException('Respons ringkasan notifikasi tidak valid');
    }

    return NotificationSummaryModel.fromJson(ringkasan);
  }

  Future<void> markAllRead({required String token}) async {
    await _apiService.post('/notifications/read-all', {}, token: token);
  }

  Future<void> delete({required String token, required String id}) async {
    await _apiService.delete('/notifications/$id', token: token);
  }
}
