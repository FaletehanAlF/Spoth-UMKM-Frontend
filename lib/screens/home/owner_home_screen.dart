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
import '../../widgets/notification_icon.dart';
import '../../widgets/place_grid.dart';
import '../../widgets/riwayat_icon_button.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_page.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nama = ref.watch(
      authNotifierProvider.select((state) => state.user?.nama),
    );
    final sapaan = namaDepan(nama);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpothAppBar(
        title: const Text(
          'Spoth UMKM',
          style: TextStyle(
            color: AppColors.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [RiwayatIconButton(), NotificationIconButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await ref.read(myPlacesProvider.notifier).refresh();
          await ref.read(hostSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppWidth.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeHeader(sapaan: sapaan, nama: nama),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final lebar = constraints.maxWidth;
                      final ringkasan = <Widget>[
                        const _SummarySection(),
                        const SizedBox(height: 12),
                        _ManagePlacesCard(
                          onTap: () => ref
                              .read(mainNavIndexProvider.notifier)
                              .setTab(MainTab.kelolaTempat),
                        ),
                      ];

                      if (lebar < 720) {
                        return Column(children: ringkasan);
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 3, child: _SummarySection()),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: _ManagePlacesCard(
                              onTap: () => ref
                                  .read(mainNavIndexProvider.notifier)
                                  .setTab(MainTab.kelolaTempat),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SpothSectionHeader(
                    title: 'Jelajahi Tempat Lain',
                    subtitle: 'Lihat ruang usaha lain yang sedang tersedia',
                    action: _SectionLink(
                      label: 'Lihat Semua',
                      onTap: () => ref
                          .read(mainNavIndexProvider.notifier)
                          .setTab(MainTab.tempat),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _BrowsePlacesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.sapaan, required this.nama});

  final String? sapaan;
  final String? nama;

  @override
  Widget build(BuildContext context) {
    final initial = (nama ?? '').trim().isNotEmpty
        ? nama!.trim()[0].toUpperCase()
        : 'S';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sapaan != null)
                Text(
                  'Halo, $sapaan',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Ringkasan Usaha',
                style: AppFonts.heading(
                  fontSize: 28,
                  weight: 700,
                  height: 1.12,
                  letterSpacing: -0.8,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau tempat dan pesananmu dalam satu pandangan.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrowsePlacesSection extends ConsumerWidget {
  const _BrowsePlacesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(tenantPlacesProvider);

    return places.when(
      loading: () => const PlaceGridSkeleton(count: 4),
      error: (error, _) => EmptyState(
        icon: Icons.wifi_off,
        title: 'Gagal memuat tempat',
        message:
            'Periksa koneksi internet Anda lalu tarik ke bawah untuk '
            'mencoba lagi.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.storefront,
            title: 'Belum ada tempat lain',
            message: 'Belum ada tempat usaha lain yang terdaftar saat ini.',
          );
        }

        return PlaceGrid(places: items.take(4).toList());
      },
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

class _ManagePlacesCard extends StatelessWidget {
  const _ManagePlacesCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.primaryDeep,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Tempat',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Lihat, edit, dan atur ketersediaan tempatmu',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hostSummaryProvider);

    return summary.when(
      loading: () => const SummarySkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat ringkasan',
        message:
            'Periksa koneksi internet Anda lalu tarik ke bawah untuk '
            'mencoba lagi.',
      ),
      data: (value) {
        if (value == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _RevenueCard(
              pendapatan: value.totalPendapatan,
              menungguBayar: value.pemesananMenunggu,
              lunas: value.pemesananLunas,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.storefront,
                    label: 'Total Tempat',
                    value: '${value.totalTempat}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Tempat Aktif',
                    value: '${value.tempatAktif}',
                    tone: AppColors.sage,
                    surface: AppColors.sageTint,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.pendapatan,
    required this.menungguBayar,
    required this.lunas,
  });

  final double pendapatan;
  final int menungguBayar;
  final int lunas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 17,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      'Dari penyewaan yang sudah lunas',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(pendapatan),
              style: AppFonts.heading(
                fontSize: 30,
                weight: 700,
                letterSpacing: -0.9,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.softBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RevenueFact(
                  label: 'Menunggu Bayar',
                  value: '$menungguBayar',
                ),
              ),
              Expanded(
                child: _RevenueFact(label: 'Lunas', value: '$lunas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueFact extends StatelessWidget {
  const _RevenueFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AppColors.primaryDeep,
    this.surface = AppColors.lightOrange,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
