import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/notification_model.dart';
import '../../providers/nav_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    Widget dibatasi(Widget child) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppWidth.list),
          child: child,
        ),
      );
    }

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
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
        loading: () => dibatasi(
          const Padding(
            padding: EdgeInsets.all(20),
            child: NotificationListSkeleton(count: 5),
          ),
        ),
        error: (error, _) => dibatasi(
          Center(
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
        ),
        data: (page) {
          final items = page.items;

          if (items.isEmpty) {
            return dibatasi(
              const Center(
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
              ),
            );
          }

          return dibatasi(
            RefreshIndicator(
              color: AppColors.primaryDeep,
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length + (page.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () => ref
                              .read(notificationsProvider.notifier)
                              .loadMore(),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Muat Lebih Banyak'),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(notification: items[index]),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.tempat, child: page);
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dibaca = notification.dibaca;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: dibaca
                  ? AppColors.softBorder
                  : AppColors.primaryDeep.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dibaca
                      ? AppColors.surfaceMuted
                      : AppColors.lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  dibaca ? Icons.notifications_none : Icons.notifications,
                  size: 20,
                  color: dibaca
                      ? AppColors.secondaryText
                      : AppColors.primaryDeep,
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
                        height: 1.35,
                        fontWeight: dibaca ? FontWeight.w500 : FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.pesan,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
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
                  margin: const EdgeInsets.only(top: 4),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDeep,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Hapus notifikasi',
                color: AppColors.secondaryText,
                onPressed: () async {
                  await ref
                      .read(notificationsProvider.notifier)
                      .delete(notification.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifikasi dihapus')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
