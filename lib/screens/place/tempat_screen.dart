import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/place_catalog.dart';
import '../../widgets/spoth_app_bar.dart';

class TempatScreen extends ConsumerWidget {
  const TempatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final roleDikenal = user != null &&
        (user.role == UserModel.roleHost || user.role == UserModel.roleTenant);

    if (!roleDikenal) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: const SpothAppBar(
          title: Text('Tempat'),
          actions: [NotificationIconButton()],
        ),
        body: const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Role akun tidak dikenali',
              message:
                  'Tolong keluar dan login kembali, atau hubungi administrator.',
            ),
          ),
        ),
      );
    }

    return const _TempatKatalogPage();
  }
}

class _TempatKatalogPage extends StatelessWidget {
  const _TempatKatalogPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(
        title: Text('Tempat'),
        actions: [NotificationIconButton()],
      ),
      body: const SafeArea(child: PlaceCatalog()),
    );
  }
}
