import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../models/notification_model.dart';

/// Koneksi Socket.IO pusat untuk notifikasi real-time.
///
/// - Satu koneksi saja (singleton lewat provider); dipanggil sekali saat login.
/// - Token JWT dikirim lewat handshake `auth.token` (BUKAN query parameter).
/// - Setiap event `notification:new` diteruskan ke [onNotification].
/// - Reconnect otomatis: backoff 1 detik, maks 5 percobaan, lalu berhenti
///   (pencegahan infinite loop; pengguna bisa logout-login ulang).
/// - Koneksi ditutup saat pengguna logout (lewat [disconnect]).
class NotificationSocketService {
  NotificationSocketService(this._host);

  /// Host backend tanpa path `/api` (mis. `http://localhost:3000`).
  final String _host;

  sio.Socket? _socket;

  /// Callback saat notifikasi baru masuk (event `notification:new`).
  void Function(NotificationModel notification)? onNotification;

  bool get isConnected => _socket?.connected ?? false;

  /// Membuka koneksi ke Socket.IO server backend.
  ///
  /// Jika sudah terhubung, tidak melakukan apa-apa.
  /// Jika ada koneksi lama (mis. setelah logout), dibersihkan dulu.
  void connect(String token) {
    if (_socket?.connected ?? false) {
      return;
    }

    disconnect(); // Buang koneksi lama bila ada.

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

  /// Memutus koneksi dan membersihkan listener (dipanggil saat logout).
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  /// Mengubah payload event menjadi [NotificationModel].
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
