import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  const AppConfig._();

  static const String appName = 'SPOTH UMKM';

  static const String lanHost = '192.168.1.7';

  // Samakan dengan PORT di file .env backend (saat ini 3003).
  static const int port = 3003;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    return 'http://$lanHost:$port/api';
  }
}
