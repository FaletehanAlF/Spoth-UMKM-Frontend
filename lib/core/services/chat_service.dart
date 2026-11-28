import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../models/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(apiServiceProvider));
});

/// Simple REST chat. Realtime handled by app socket but REST is source of truth.
class ChatService {
  ChatService(this._apiService);

  final ApiService _apiService;

  Future<List<ChatConversation>> conversations({required String token}) async {
    final body = await _apiService.get('/chat/conversations', token: token);
    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['conversations'] as List<dynamic>? ?? const [];
    return items.whereType<Map<String, dynamic>>().map(ChatConversation.fromJson).toList();
  }

  Future<List<ChatMessageModel>> messages({required String token, required String bookingId}) async {
    final body = await _apiService.get('/chat/$bookingId/messages', token: token);
    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['messages'] as List<dynamic>? ?? const [];
    return items.whereType<Map<String, dynamic>>().map(ChatMessageModel.fromJson).toList();
  }

  Future<int> markRead({required String token, required String bookingId}) async {
    final response = await _apiService.post(
      '/chat/$bookingId/read',
      const <String, dynamic>{},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final total = data?['total'];
    return total is num ? total.toInt() : 0;
  }

  Future<ChatBlockStatus> blockStatus({required String token, required String bookingId}) async {
    final response = await _apiService.get('/chat/$bookingId/block-status', token: token);
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return ChatBlockStatus.fromJson(data);
  }

  Future<void> blockContact({required String token, required String bookingId}) async {
    await _apiService.post('/chat/$bookingId/block', const <String, dynamic>{}, token: token);
  }

  Future<void> unblockContact({required String token, required String bookingId}) async {
    await _apiService.delete('/chat/$bookingId/block', token: token);
  }

  Future<ChatMessageModel> editMessage({
    required String token,
    required String bookingId,
    required String messageId,
    required String body,
  }) async {
    final response = await _apiService.patch(
      '/chat/$bookingId/messages/$messageId',
      <String, dynamic>{'body': body},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final message = data?['message'] as Map<String, dynamic>?;
    if (message == null) throw const FormatException('Respons edit pesan tidak valid');
    return ChatMessageModel.fromJson(message);
  }

  Future<void> deleteMessage({
    required String token,
    required String bookingId,
    required String messageId,
  }) async {
    await _apiService.delete('/chat/$bookingId/messages/$messageId', token: token);
  }

  Future<ChatMessageModel> send({required String token, required String bookingId, required String body}) async {
    final response = await _apiService.post(
      '/chat/$bookingId/messages',
      <String, dynamic>{'body': body},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final message = data?['message'] as Map<String, dynamic>?;
    if (message == null) throw const FormatException('Respons pesan tidak valid');
    return ChatMessageModel.fromJson(message);
  }
}

class ChatBlockStatus {
  const ChatBlockStatus({
    required this.blocked,
    required this.blockedByMe,
    required this.blockedByOther,
  });

  final bool blocked;
  final bool blockedByMe;
  final bool blockedByOther;

  factory ChatBlockStatus.fromJson(Map<String, dynamic> json) {
    return ChatBlockStatus(
      blocked: json['blocked'] == true,
      blockedByMe: json['blocked_by_me'] == true,
      blockedByOther: json['blocked_by_other'] == true,
    );
  }
}
