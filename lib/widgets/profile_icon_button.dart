import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/nav_provider.dart';

/// Icon profile di pojok kanan atas, samping notifikasi.
class ProfileIconButton extends ConsumerWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.user));
    final image = user?.foto ?? '';

    return IconButton(
      tooltip: 'Profil',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.lightOrange,
        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
        child: image.isEmpty
            ? const Icon(Icons.person, size: 18, color: AppColors.primaryOrange)
            : null,
      ),
      onPressed: () {
        ref.read(mainNavIndexProvider.notifier).setTab(MainTab.profil);
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
    );
  }
}
