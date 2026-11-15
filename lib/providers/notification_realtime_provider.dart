import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/notification_socket_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

/// Host backend tanpa suffix `/api` untuk koneksi Socket.IO.
String _socketHost() {
  final base = AppConfig.baseUrl;
  const suffix = '/api';
  return base.endsWith(suffix)
      ? base.substring(0, base.length - suffix.length)
      : base;
}

/// Provider koneksi Socket.IO pusat.
final notificationSocketServiceProvider = Provider<NotificationSocketService>(
  (ref) => NotificationSocketService(_socketHost()),
);

/// Sinkronisasi realtime notifikasi dengan sesi login:
///
/// - Login/restore sesi → konek ke Socket.IO (event `notification:new`).
/// - Event masuk → refresh daftar + badge unread + tampilkan notifikasi lokal.
/// - Logout → putus Socket.IO (listener dibersihkan).
///
/// Provider ini SENGAJA hanya di-watch oleh `SpothApp` agar lifecycle-nya
/// mengikuti aplikasi, bukan per halaman.
class NotificationRealtimeNotifier extends Notifier<bool> {
  NotificationSocketService get _service =>
      ref.read(notificationSocketServiceProvider);

  @override
  bool build() {
    ref.listen(
      authNotifierProvider,
      (_, next) => _sync(next),
      fireImmediately: true,
    );
    return _service.isConnected;
  }

  void _sync(AuthState state) {
    final token = state.token;

    if (token != null) {
      _connect(token);
    } else {
      _disconnect();
    }
  }

  void _connect(String token) {
    if (_service.isConnected) {
      return;
    }

    // Pasang callback sekali (connect sebelumnya membersihkan listener lama
    // via disconnect()).
    _service.onNotification = _onNewNotification;
    _service.connect(token);
    state = true;

    // Siapkan notifikasi lokal + izin Android 13+ (idempoten).
    unawaited(LocalNotificationService.instance.init());
  }

  void _disconnect() {
    _service.onNotification = null;
    _service.disconnect();
    state = false;
  }

  void _onNewNotification(NotificationModel notification) {
    // Perbarui daftar & badge unread dari server (sumber kebenaran).
    unawaited(ref.read(notificationsProvider.notifier).refresh());
    unawaited(ref.read(notificationSummaryProvider.notifier).refresh());

    // Tampilkan notifikasi lokal (no-op di Flutter Web).
    unawaited(
      LocalNotificationService.instance.showFromNotification(notification),
    );
  }
}

/// Provider sinkronisasi realtime (disaksikan oleh `SpothApp`).
final notificationRealtimeProvider =
    NotifierProvider<NotificationRealtimeNotifier, bool>(
      NotificationRealtimeNotifier.new,
    );
