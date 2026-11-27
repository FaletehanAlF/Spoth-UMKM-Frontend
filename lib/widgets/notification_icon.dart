import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';

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
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifikasi',
      onPressed: () => context.push('/notifications'),
    );
  }
}
