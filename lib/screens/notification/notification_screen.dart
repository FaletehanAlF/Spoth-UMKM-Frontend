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

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  Widget _dibatasi(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppWidth.list),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(title: Text('Notifikasi')),
      body: notifications.when(
        loading: () => _dibatasi(
          const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTitleSkeleton(subtitleWidth: 180),
                SizedBox(height: 18),
                NotificationListSkeleton(count: 5),
              ],
            ),
          ),
        ),
        error: (error, _) => _dibatasi(
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
        data: (halaman) {
          final items = halaman.items;

          if (items.isEmpty) {
            return _dibatasi(
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 44,
                        color: AppColors.primaryDeep,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Belum ada notifikasi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Notifikasi akan muncul di sini ketika ada aktivitas '
                        'penyewaan terkait akun Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _dibatasi(
            RefreshIndicator(
              color: AppColors.primaryDeep,
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length + (halaman.hasMore ? 1 : 0),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.judul,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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
    );
  }
}
