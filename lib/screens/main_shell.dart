import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/nav_provider.dart';
import '../widgets/bottom_nav_pill.dart';
import '../widgets/nav_items.dart';
import '../widgets/spoth_sidebar.dart';
import 'booking/booking_screen.dart';
import 'home/home_screen.dart';
import 'place/kelola_tempat_screen.dart';
import 'place/tempat_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final tabs = tabsForRole(user);
    final tab = ref.watch(mainNavIndexProvider);

    var index = tabs.indexOf(tab);
    if (index < 0) {
      index = 0;
    }

    final items = [for (final item in tabs) kNavItems[item]!];

    final content = IndexedStack(
      index: index,
      children: [
        for (final item in tabs)
          switch (item) {
            MainTab.beranda => const HomeScreen(),
            MainTab.tempat => const TempatScreen(),
            MainTab.kelolaTempat => const KelolaTempatScreen(),
            MainTab.booking => const BookingScreen(),
            MainTab.profil => const ProfileScreen(),
          },
      ],
    );

    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 900;

    if (showSidebar) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Row(
          children: [
            SpothSidebar(
              index: index,
              items: items,
              expanded: width >= 1400,
              onChanged: (value) =>
                  ref.read(mainNavIndexProvider.notifier).setTab(tabs[value]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: SpothBottomNav(
        index: index,
        items: items,
        onChanged: (value) =>
            ref.read(mainNavIndexProvider.notifier).setTab(tabs[value]),
      ),
    );
  }
}
