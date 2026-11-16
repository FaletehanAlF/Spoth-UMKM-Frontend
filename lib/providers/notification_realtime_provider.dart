import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/notification_socket_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

String _socketHost() {
  final base = AppConfig.baseUrl;
  const suffix = '/api';
  return base.endsWith(suffix)
      ? base.substring(0, base.length - suffix.length)
      : base;
}

final notificationSocketServiceProvider = Provider<NotificationSocketService>(
  (ref) => NotificationSocketService(_socketHost()),
);

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

    _service.onNotification = _onNewNotification;
    _service.connect(token);
    state = true;

    unawaited(LocalNotificationService.instance.init());
  }

  void _disconnect() {
    _service.onNotification = null;
    _service.disconnect();
    state = false;
  }

  void _onNewNotification(NotificationModel notification) {
    unawaited(ref.read(notificationsProvider.notifier).refresh());
    unawaited(ref.read(notificationSummaryProvider.notifier).refresh());

    unawaited(
      LocalNotificationService.instance.showFromNotification(notification),
    );
  }
}

final notificationRealtimeProvider =
    NotifierProvider<NotificationRealtimeNotifier, bool>(
      NotificationRealtimeNotifier.new,
    );
