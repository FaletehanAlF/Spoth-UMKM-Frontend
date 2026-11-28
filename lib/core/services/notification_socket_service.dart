import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../models/notification_model.dart';

class NotificationSocketService {
  NotificationSocketService(this._host);

  final String _host;

  sio.Socket? _socket;

  void Function(NotificationModel notification)? onNotification;

  /// Semua listener dapat menerima `chat:message`; tidak saling menimpa.
  final List<void Function(Map<String, dynamic> data)> _chatListeners = [];

  void Function(Map<String, dynamic> data)? onChatMessageUpdated;
  void Function(Map<String, dynamic> data)? onChatMessageDeleted;

  bool get isConnected => _socket?.connected ?? false;

  void addChatMessageListener(void Function(Map<String, dynamic>) listener) {
    if (!_chatListeners.contains(listener)) {
      _chatListeners.add(listener);
    }
  }

  void removeChatMessageListener(void Function(Map<String, dynamic>) listener) {
    _chatListeners.remove(listener);
  }

  void connect(String token) {
    if (_socket?.connected ?? false) {
      return;
    }

    disconnect();

    final socket = sio.io(
      _host,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    socket.on('notification:new', (dynamic data) {
      final notification = _parse(data);
      if (notification != null) {
        onNotification?.call(notification);
      }
    });

    socket.on('chat:message', (dynamic data) {
      if (data is! Map) return;

      final message = Map<String, dynamic>.from(data);
      // Salin list agar listener boleh add/remove ketika event berjalan.
      for (final listener in List.of(_chatListeners)) {
        listener(message);
      }
    });

    socket.on('chat:message-updated', (dynamic data) {
      if (data is Map) {
        onChatMessageUpdated?.call(Map<String, dynamic>.from(data));
      }
    });

    socket.on('chat:message-deleted', (dynamic data) {
      if (data is Map) {
        onChatMessageDeleted?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    onChatMessageUpdated = null;
    onChatMessageDeleted = null;
  }

  NotificationModel? _parse(dynamic data) {
    if (data is! Map) {
      return null;
    }

    try {
      return NotificationModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}
