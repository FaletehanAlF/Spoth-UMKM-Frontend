import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/place_grid_card.dart';
import '../../widgets/shimmer_loading.dart';

/// Home untuk role **Penyewa (TENANT)**:
///
/// - Headline + preview beberapa tempat (dari `GET /places`).
/// - Tombol "Lihat Semua Tempat" menuju tab Tempat (katalog lengkap).
/// - Akses notifikasi. Aksi CRUD tempat tidak tersedia untuk Penyewa.
class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        centerTitle: true,
        title: const Text(
          'SPOTH UMKM',
          style: TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [NotificationIconButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () => ref.read(tenantPlacesProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temukan\nTempat Usahamu',
                style: AppFonts.serif(
                  fontSize: 30,
                  weight: 600,
                  height: 1.15,
                  letterSpacing: -0.5,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tempat Usaha',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 10),
              const _PlacePreviewGrid(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(mainNavIndexProvider.notifier).setTab(1),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Lihat Semua Tempat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview beberapa tempat (maks. 4) pada Beranda.
/// Katalog lengkap (pencarian + filter) ada di tab Tempat.
class _PlacePreviewGrid extends ConsumerWidget {
  const _PlacePreviewGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(tenantPlacesProvider);

    return places.when(
      loading: () => const PlaceListSkeleton(count: 4),
      error: (error, _) => EmptyState(
        icon: Icons.wifi_off,
        title: 'Gagal memuat tempat',
        message: 'Periksa koneksi internet Anda lalu coba lagi.',
        actionLabel: 'Coba Lagi',
        onAction: () => ref.read(tenantPlacesProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.storefront,
            title: 'Belum ada tempat tersedia',
            message:
                'Belum ada tempat usaha yang bisa disewa saat ini. '
                'Coba lagi nanti.',
          );
        }

        final preview = items.take(4).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: preview.length,
          itemBuilder: (context, index) => PlaceGridCard(place: preview[index]),
        );
      },
    );
  }
}
