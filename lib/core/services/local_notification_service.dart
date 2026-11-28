import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/chat_message.dart';
import '../../models/notification_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'spoth_notifications',
    'Notifikasi SPOTH UMKM',
    description: 'Notifikasi pemesanan dan penyewaan tempat',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized || kIsWeb) {
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(settings: initSettings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);

      await android?.requestNotificationsPermission();

      _initialized = true;
    } catch (error) {
      debugPrint('Gagal menyiapkan notifikasi lokal: $error');
    }
  }

  Future<void> showFromNotification(NotificationModel notification) async {
    await _show(
      id: notification.id.hashCode,
      title: notification.judul,
      body: notification.pesan,
    );
  }

  /// Tampilkan notifikasi HP beneran ketika ada pesan chat baru.
  Future<void> showChat(ChatMessageModel message) async {
    await _show(
      id: 'chat-${message.id}'.hashCode,
      title: 'Pesan baru di Chat',
      body: message.body,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await init();

    if (!_initialized) {
      return;
    }

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'spoth_notifications',
            'Notifikasi SPOTH UMKM',
            channelDescription: 'Notifikasi pemesanan dan penyewaan tempat',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFF97316),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Gagal menampilkan notifikasi lokal: $error');
    }
  }
}
