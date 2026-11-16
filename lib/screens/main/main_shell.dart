import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/bottom_nav_pill.dart';
import '../../widgets/spoth_sidebar.dart';
import '../booking/booking_screen.dart';
import '../home/home_screen.dart';
import '../place/tempat_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainNavIndexProvider);
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 900;

    final content = IndexedStack(
      index: index,
      children: const [
        HomeScreen(),
        TempatScreen(),
        BookingScreen(),
        ProfileScreen(),
      ],
    );

    if (showSidebar) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Row(
          children: [
            SpothSidebar(
              index: index,
              expanded: width >= 1100,
              onChanged: (value) =>
                  ref.read(mainNavIndexProvider.notifier).setTab(value),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: SpothBottomNav(
        index: index,
        onChanged: (value) =>
            ref.read(mainNavIndexProvider.notifier).setTab(value),
      ),
    );
  }
}
