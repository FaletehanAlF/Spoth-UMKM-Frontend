import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/notification_model.dart';

/// Pembungkus `flutter_local_notifications` untuk menampilkan notifikasi
/// perangkat saat aplikasi sedang aktif.
///
/// Catatan: aplikasi tujuan utama (SPOTH UMKM) berjalan di Android.
/// Di Flutter Web, notifikasi lokal di-skip (web butuh Web Notification
/// API yang berbeda) — event socket tetap memperbarui daftar & badge.
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

  /// Menyiapkan plugin + membuat channel Android + minta izin (Android 13+).
  /// Aman dipanggil berkali-kali; hanya menjalankan sekali.
  Future<void> init() async {
    if (_initialized || kIsWeb) {
      return;
    }

    try {
      // Icon kecil notifikasi (memakai mipmap launcher yang sudah ada).
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(settings: initSettings);

      // Channel Android 8+ (wajib dibuat sebelum notifikasi ditampilkan).
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);

      // Izin POST_NOTIFICATIONS pada Android 13+.
      await android?.requestNotificationsPermission();

      _initialized = true;
    } catch (error) {
      // Notifikasi lokal tidak boleh membuat aplikasi crash.
      debugPrint('Gagal menyiapkan notifikasi lokal: $error');
    }
  }

  /// Menampilkan notifikasi perangkat dari notifikasi backend.
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
