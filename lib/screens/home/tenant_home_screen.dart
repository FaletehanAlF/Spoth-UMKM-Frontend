import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/place_grid.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_page.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nama = ref.watch(
      authNotifierProvider.select((state) => state.user?.nama),
    );
    final sapaan = namaDepan(nama);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(
        title: Text(
          'Spoth UMKM',
          style: TextStyle(
            color: AppColors.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        showRiwayat: true,
        showNotification: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () => ref.read(tenantPlacesProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppWidth.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(
                    sapaan: sapaan,
                    onCari: () => ref
                        .read(mainNavIndexProvider.notifier)
                        .setTab(MainTab.tempat),
                    onKategori: (kategori) {
                      ref
                          .read(tenantSearchProvider.notifier)
                          .setKategori(kategori);
                      ref
                          .read(mainNavIndexProvider.notifier)
                          .setTab(MainTab.tempat);
                    },
                  ),
                  const SizedBox(height: 28),
                  SpothSectionHeader(
                    title: 'Tempat Usaha',
                    subtitle: 'Pilihan ruang yang bisa kamu sewa sekarang',
                    action: _SectionLink(
                      label: 'Lihat Semua',
                      onTap: () => ref
                          .read(mainNavIndexProvider.notifier)
                          .setTab(MainTab.tempat),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _PlacePreviewGrid(),
                  const SizedBox(height: 24),
                  const _EntryNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.sapaan,
    required this.onCari,
    required this.onKategori,
  });

  final String? sapaan;
  final VoidCallback onCari;
  final ValueChanged<String> onKategori;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lebar = constraints.maxWidth >= 720;

        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sapaan != null) ...[
              Text(
                'Halo, $sapaan',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Temukan\nTempat Usahamu',
              style: AppFonts.heading(
                fontSize: lebar ? 40 : 31,
                weight: 700,
                height: 1.08,
                letterSpacing: lebar ? -1.3 : -0.8,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pilih ruang yang dekat dengan pelangganmu, '
              'mulai dari lapak kecil sampai booth event.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            _SearchShortcut(onTap: onCari),
          ],
        );

        if (!lebar) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.canvasDeep,
              borderRadius: BorderRadius.circular(AppRadius.xl + 2),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: intro,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 26, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.canvasDeep,
            borderRadius: BorderRadius.circular(AppRadius.xl + 2),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: intro),
              const SizedBox(width: 28),
              Expanded(flex: 2, child: _CategoryShortcuts(onTap: onKategori)),
            ],
          ),
        );
      },
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
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          height: 54,
          padding: const EdgeInsets.fromLTRB(16, 6, 7, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.secondaryText),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari tempat, kecamatan, atau lokasi...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              SizedBox(width: 8),
              _SearchButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primaryDeep,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
    );
  }
}

class _CategoryShortcuts extends StatelessWidget {
  const _CategoryShortcuts({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mulai dari kebutuhanmu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          _CategoryRow(
            icon: Icons.storefront_outlined,
            label: 'Lapak usaha',
            onTap: () => onTap('LAPAK_USAHA'),
          ),
          _CategoryRow(
            icon: Icons.deck_outlined,
            label: 'Teras komersial',
            onTap: () => onTap('TERAS_KOMERSIAL'),
          ),
          _CategoryRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booth event',
            onTap: () => onTap('BOOTH_EVENT'),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.primaryDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
        if (!last) const Divider(height: 1, color: AppColors.softBorder),
      ],
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryNote extends StatelessWidget {
  const _EntryNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: AppColors.sage),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Punya tempat usaha? Daftarkan lapak, teras, atau booth-mu '
              'agar bisa ditemukan calon penyewa.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
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


