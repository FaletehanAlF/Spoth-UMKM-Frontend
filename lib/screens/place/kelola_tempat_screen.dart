import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/place_provider.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/owner_place_list.dart';
import '../../widgets/spoth_app_bar.dart';

class KelolaTempatScreen extends ConsumerWidget {
  const KelolaTempatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(
        title: Text('Kelola Tempat'),
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
