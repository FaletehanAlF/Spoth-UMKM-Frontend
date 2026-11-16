import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../models/notification_model.dart';

class NotificationSocketService {
  NotificationSocketService(this._host);

  final String _host;

  sio.Socket? _socket;

  void Function(NotificationModel notification)? onNotification;

  bool get isConnected => _socket?.connected ?? false;

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

    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
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
