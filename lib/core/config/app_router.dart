import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Konfigurasi dasar navigasi GoRouter.
///
/// Rute masih placeholder sementara sampai halaman utama dibuat.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _HomePlaceholder(),
    ),
  ],
);

// Placeholder sementara untuk rute `/`.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightOrange,
      body: Center(
        child: Text(
          'SPOTH UMKM',
          style: TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
