import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/place_grid.dart';
import '../../widgets/spoth_app_bar.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nama = ref.watch(
      authNotifierProvider.select((state) => state.user?.nama),
    );
    final sapaan = namaDepan(nama);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: const Text(
          'Spoth UMKM',
          style: TextStyle(
            color: AppColors.darkText,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sapaan != null) ...[
                    Text(
                      'Halo, $sapaan',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'Temukan\nTempat Usahamu',
                    style: AppFonts.heading(
                      fontSize: 30,
                      weight: 600,
                      height: 1.15,
                      letterSpacing: -0.5,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SearchShortcut(
                    onTap: () =>
                        ref.read(mainNavIndexProvider.notifier).setTab(1),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tempat Usaha',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      _SectionLink(
                        label: 'Lihat Semua',
                        onTap: () => ref.read(
                          mainNavIndexProvider.notifier,
                        ).setTab(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const _PlacePreviewGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchShortcut extends StatelessWidget {
  const _SearchShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.secondaryText),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari tempat, kota, atau lokasi...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacePreviewGrid extends ConsumerWidget {
  const _PlacePreviewGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(tenantPlacesProvider);

    return places.when(
      loading: () => const PlaceGridSkeleton(count: 4),
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

        return PlaceGrid(places: items.take(4).toList());
      },
    );
  }
}
