import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  const AppConfig._();

  static const String appName = 'SPOTH UMKM';

  static const String lanHost = '10.2.10.58';

  static const int port = 3000;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    return 'http://$lanHost:$port/api';
  }
}
