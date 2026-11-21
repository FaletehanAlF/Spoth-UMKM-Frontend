import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/place_provider.dart';
import '../../widgets/owner_place_list.dart';
import '../../widgets/spoth_app_bar.dart';

class KelolaTempatScreen extends ConsumerWidget {
  const KelolaTempatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      floatingActionButton: FloatingActionButton.extended(
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
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await ref.read(myPlacesProvider.notifier).refresh();
          await ref.read(hostSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: const OwnerPlaceList(),
            ),
          ),
        ),
      ),
    );
  }
}
