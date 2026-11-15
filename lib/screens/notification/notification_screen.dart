import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Halaman Notifikasi (`GET /notifications`).
///
/// Isi notifikasi berasal dari backend dan otomatis menyesuaikan role:
/// Pemilik menerima pemberitahuan pemesanan tempat miliknya, Penyewa
/// menerima pemberitahuan status penyewaannya. Frontend tidak membuat
/// notifikasi palsu.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: NotificationListSkeleton(count: 5),
        ),
        error: (error, _) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: EmptyState(
              icon: Icons.wifi_off,
              title: 'Gagal memuat notifikasi',
              message: 'Periksa koneksi internet Anda lalu coba lagi.',
              actionLabel: 'Coba Lagi',
              onAction: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.notifications_none,
                  title: 'Belum ada notifikasi',
                  message:
                      'Notifikasi akan muncul di sini ketika ada aktivitas '
                      'penyewaan terkait akun Anda.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _NotificationCard(notification: items[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Kartu satu notifikasi. Ketuk untuk menandai sudah dibaca.
/// Notifikasi yang belum dibaca ditandai dengan garis tepi orange.
class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dibaca = notification.dibaca;

    return Material(
      color: AppColors.lightOrange,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: dibaca
            ? null
            : () async {
                await ref
                    .read(notificationsProvider.notifier)
                    .markRead(notification.id);
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dibaca
                  ? AppColors.lightOrange
                  : AppColors.primaryOrange.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  dibaca ? Icons.notifications_none : Icons.notifications,
                  color: dibaca
                      ? AppColors.secondaryText
                      : AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.judul,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: dibaca ? FontWeight.w500 : FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.pesan,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatTanggalJam(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (!dibaca) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
