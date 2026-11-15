import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/bottom_nav_pill.dart';
import '../booking/booking_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

/// Kerangka halaman utama dengan bottom navigation berbentuk pill:
/// Beranda (kiri), Booking (tengah), Profil (kanan).
///
/// Memakai [IndexedStack] agar state setiap tab tetap terjaga
/// ketika pengguna berpindah-pindah tab.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: index,
        children: const [HomeScreen(), BookingScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: SpothBottomNav(
        index: index,
        onChanged: (value) =>
            ref.read(mainNavIndexProvider.notifier).setTab(value),
      ),
    );
  }
}
