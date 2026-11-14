import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';

/// Konfigurasi navigasi GoRouter.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);

/// Layar singkat yang menentukan rute awal berdasarkan status onboarding & token.
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  static const _storage = FlutterSecureStorage();
  static const _completedKey = 'onboarding_completed';

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    try {
      final onboardingDone = await _storage.read(key: _completedKey);
      if (!mounted) return;

      if (onboardingDone != 'true') {
        context.go('/onboarding');
        return;
      }

      final token = await _storage.read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        final ok = await ref
            .read(authNotifierProvider.notifier)
            .restoreSession();
        if (!mounted) return;
        if (ok) {
          context.go('/home');
          return;
        }
      }

      if (mounted) context.go('/login');
    } catch (_) {
      // Penyimpanan lokal tidak tersedia (mis. saat test): arahkan ke onboarding.
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightOrange,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront,
              size: 72,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 16),
            const Text(
              'SPOTH UMKM',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primaryOrange),
          ],
        ),
      ),
    );
  }
}
