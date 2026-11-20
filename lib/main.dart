import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_realtime_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pulihkan sesi sebelum runApp agar refresh di web tidak mengeluarkan
  // pengguna yang masih login (token tetap tersimpan di secure storage).
  final container = ProviderContainer();
  try {
    await container.read(authNotifierProvider.notifier).restoreSession();
  } catch (_) {
    // Abaikan; aplikasi tetap berjalan dan pengguna diarahkan ke login.
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const SpothApp()),
  );
}

class SpothApp extends ConsumerWidget {
  const SpothApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRealtimeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
