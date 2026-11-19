import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/riwayat_provider.dart';

class RiwayatIconButton extends ConsumerWidget {
  const RiwayatIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(riwayatBadgeProvider).value ?? 0;

    return IconButton(
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.history_rounded),
      ),
      tooltip: 'Riwayat',
      onPressed: () async {
        await context.push('/riwayat');
        await ref.read(riwayatBadgeProvider.notifier).markAllSeen();
        await ref.read(riwayatBadgeProvider.notifier).refresh();
      },
    );
  }
}
