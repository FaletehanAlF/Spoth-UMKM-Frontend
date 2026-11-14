import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi dasar aplikasi SPOTH UMKM.
class AppConfig {
  const AppConfig._();

  static const String appName = 'SPOTH UMKM';

  /// Base URL backend, otomatis menyesuaikan platform tempat aplikasi
  /// dijalankan:
  ///
  /// - **Flutter Web (Chrome)**: browser berjalan langsung di komputer host,
  ///   sehingga backend dijangkau via `localhost`.
  /// - **Android Emulator**: `10.0.2.2` adalah alamat khusus emulator yang
  ///   menunjuk ke `localhost` di komputer host.
  /// - **HP fisik**: perlu diganti ke IP LAN komputer host (mis. 192.168.x.x)
  ///   karena `10.0.2.2` tidak berlaku di luar emulator.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return 'http://10.0.2.2:3000/api';
  }
}
