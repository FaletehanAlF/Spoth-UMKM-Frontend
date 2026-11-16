import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/owner_place_list.dart';
import '../../widgets/place_catalog.dart';
import '../../widgets/spoth_app_bar.dart';

class TempatScreen extends ConsumerWidget {
  const TempatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    if (user?.role == UserModel.roleHost) {
      return const _OwnerTempatPage();
    }
    if (user?.role == UserModel.roleTenant) {
      return const _TenantTempatPage();
    }

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
}

class _OwnerTempatPage extends ConsumerWidget {
  const _OwnerTempatPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(
        title: Text('Tempat'),
        actions: [NotificationIconButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tempat'),
        onPressed: () async {
          final saved = await context.push('/place-form');
          if (saved == true && context.mounted) {
            await ref.read(myPlacesProvider.notifier).refresh();
            await ref.read(hostSummaryProvider.notifier).refresh();
          }
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async {
          await ref.read(myPlacesProvider.notifier).refresh();
          await ref.read(hostSummaryProvider.notifier).refresh();
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: OwnerPlaceList(),
        ),
      ),
    );
  }
}

class _TenantTempatPage extends StatelessWidget {
  const _TenantTempatPage();

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
