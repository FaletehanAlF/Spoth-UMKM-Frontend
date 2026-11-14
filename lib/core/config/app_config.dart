/// Konfigurasi dasar aplikasi SPOTH UMKM.
class AppConfig {
  const AppConfig._();

  static const String appName = 'SPOTH UMKM';

  /// Base URL backend.
  /// `10.0.2.2` adalah alamat khusus Android Emulator yang menunjuk
  /// ke `localhost` di komputer host tempat backend berjalan.
  static const String baseUrl = 'http://10.0.2.2:3000/api';
}
