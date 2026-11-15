import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';

/// Icon notifikasi dengan badge jumlah belum dibaca (data nyata dari
/// `GET /notifications/summary`). Dipakai di AppBar Home Pemilik & Penyewa.
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(notificationSummaryProvider).value?.belumDibaca ?? 0;

    return IconButton(
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifikasi',
      onPressed: () => context.push('/notifications'),
    );
  }
}
