import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    if (kIsWeb) {
      return;
    }

    await init();

    if (!_initialized) {
      return;
    }

    try {
      await _plugin.show(
        id: notification.id.hashCode,
        title: notification.judul,
        body: notification.pesan,
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
