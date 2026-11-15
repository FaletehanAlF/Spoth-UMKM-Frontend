import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'owner_home_screen.dart';
import 'tenant_home_screen.dart';

/// Beranda aplikasi — memilih tampilan sesuai role pengguna yang
/// tersimpan di backend (bukan dari pilihan sementara di frontend):
///
/// - `HOST` (Pemilik)   → dashboard kelola tempat usaha.
/// - `TENANT` (Penyewa) → katalog & pencarian tempat.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final role = user?.role;

    // Hanya role yang dikenal yang diarahkan ke tampilan masing-masing.
    // Role tidak dikenal atau null tidak boleh otomatis masuk tampilan
    // Penyewa; pengguna diarahkan keluar melalui logout yang tersedia.
    if (role == UserModel.roleHost) {
      return const OwnerHomeScreen();
    }

    if (role == UserModel.roleTenant) {
      return const TenantHomeScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Role akun tidak dikenali',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akun Anda tidak memiliki peran yang valid. '
                'Silakan keluar dan hubungi administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
