import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  const AppConfig._();

  static const String appName = 'SPOTH UMKM';

  // IP laptop di jaringan Wi-Fi saat ini. Bisa diganti tanpa mengubah kode:
  // flutter run --dart-define=API_HOST=10.2.13.237
  static const String lanHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.50.199.81',
  );

  static const int port = 3004;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    return 'http://$lanHost:$port/api';
  }
}
