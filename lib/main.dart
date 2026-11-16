import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/notification_realtime_provider.dart';

void main() {
  runApp(const ProviderScope(child: SpothApp()));
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
