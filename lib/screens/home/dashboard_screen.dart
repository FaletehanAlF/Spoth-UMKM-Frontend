import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Dashboard pemilik tempat.
///
/// Susunannya mengikuti pola dashboard yang mudah dipindai:
/// 1. Sapaan + ringkasan singkat.
/// 2. Kartu KPI (pendapatan, tempat, pemesanan).
/// 3. Aksi cepat.
/// 4. Daftar tempat milik pemilik.
/// 5. Pemesanan terbaru dan ringkasan performa.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final summary = ref.watch(hostSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(
        title: Text('Dashboard'),
        showRiwayat: true,
        showNotification: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await Future.wait([
            ref.read(hostSummaryProvider.notifier).refresh(),
            ref.read(myPlacesProvider.notifier).refresh(),
            ref.read(bookingsProvider.notifier).refresh(),
          ]);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppWidth.page),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _WelcomeHeader(user: user),
                const SizedBox(height: 20),
                summary.when(
                  loading: () => const _KpiSkeleton(),
                  error: (error, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Gagal memuat ringkasan',
                    message:
                        'Periksa koneksi internet Anda lalu tarik ke bawah '
                        'untuk mencoba lagi.',
                    actionLabel: 'Coba Lagi',
                    onAction: () =>
                        ref.read(hostSummaryProvider.notifier).refresh(),
                  ),
                  data: (value) {
                    if (value == null) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NetRevenueCard(summary: value),
                        const SizedBox(height: 20),
                        _KpiGrid(summary: value),
                        const SizedBox(height: 20),
                        const _QuickActions(),
                        const SizedBox(height: 24),
                        const _RecentBookingsSection(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final sapaan = namaDepan(user?.nama);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user?.foto != null && user!.foto!.isNotEmpty)
          ClipOval(
            child: Image.network(
              user!.foto!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _AvatarFallback(),
            ),
          )
        else
          const _AvatarFallback(),
        const SizedBox(width: 12),
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
                  fontSize: 27,
                  weight: 700,
                  height: 1.1,
                  letterSpacing: -0.8,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ringkasan keuangan & tempat Anda dalam satu pandangan.',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primaryInk,
        size: 24,
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        icon: Icons.payments_outlined,
        label: 'Pendapatan',
        value: formatRupiah(summary.totalPendapatan),
        tone: AppColors.primaryDeep,
        surface: AppColors.lightOrange,
      ),
      _KpiData(
        icon: Icons.storefront_outlined,
        label: 'Total Tempat',
        value: '${summary.totalTempat}',
        tone: AppColors.primaryInk,
        surface: AppColors.lightOrange,
      ),
      _KpiData(
        icon: Icons.check_circle_outline,
        label: 'Tempat Aktif',
        value: '${summary.tempatAktif}',
        tone: AppColors.sage,
        surface: AppColors.sageTint,
      ),
      _KpiData(
        icon: Icons.receipt_long_outlined,
        label: 'Pemesanan',
        value: '${summary.totalPemesanan}',
        tone: AppColors.primaryDeep,
        surface: AppColors.lightOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 124,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _KpiCard(data: items[index]),
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.surface,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color surface;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 17, color: data.tone),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetRevenueCard extends StatelessWidget {
  const _NetRevenueCard({required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final pendapatan = summary.totalPendapatan;
    final komisi = summary.totalKomisi;
    final bersih = (pendapatan - komisi).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grafik Pendapatan Bersih',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              Text(
                formatRupiah(bersih),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Perbandingan pendapatan tercatat, komisi, dan bersih.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          _RevenueBarChart(
            pendapatan: pendapatan,
            komisi: komisi,
            bersih: bersih.toDouble(),
          ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({
    required this.pendapatan,
    required this.komisi,
    required this.bersih,
  });

  final double pendapatan;
  final double komisi;
  final double bersih;

  @override
  Widget build(BuildContext context) {
    final maksimum = [pendapatan, komisi, bersih, 1.0].reduce(
      (a, b) => a > b ? a : b,
    );

    final batang = [
      _RevenueBar('Tercatat', pendapatan, AppColors.primaryDeep),
      _RevenueBar('Komisi', komisi, AppColors.secondaryText),
      _RevenueBar('Bersih', bersih, AppColors.sage),
    ];

    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in batang)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _ringkas(item.nilai),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: item.warna,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      height: (item.nilai / maksimum * 62).clamp(6.0, 62.0),
                      width: 26,
                      decoration: BoxDecoration(
                        color: item.warna,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueBar {
  const _RevenueBar(this.label, this.nilai, this.warna);

  final String label;
  final double nilai;
  final Color warna;
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pindahTab(MainTab tab) {
      ref.read(mainNavIndexProvider.notifier).setTab(tab);
    }

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
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.storefront_outlined,
                  title: 'Kelola Tempat',
                  subtitle: 'Atur tempat & ketersediaan',
                  onTap: () => pindahTab(MainTab.kelolaTempat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat Penyewaan',
                  subtitle: 'Pantau status setiap sewa',
                  onTap: () => pindahTab(MainTab.booking),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.3,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBookingsSection extends ConsumerWidget {
  const _RecentBookingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pemesanan Terbaru',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(mainNavIndexProvider.notifier)
                    .setTab(MainTab.booking),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  ShimmerBox(width: double.infinity, height: 54, radius: 12),
                  SizedBox(height: 10),
                  ShimmerBox(width: double.infinity, height: 54, radius: 12),
                ],
              ),
            ),
            error: (error, _) => _InlineMessage(
              icon: Icons.wifi_off,
              message: 'Gagal memuat pemesanan.',
              actionLabel: 'Coba Lagi',
              onAction: () => ref.read(bookingsProvider.notifier).refresh(),
            ),
            data: (items) {
              final terbaru = items.take(3).toList();

              if (terbaru.isEmpty) {
                return const _InlineMessage(
                  icon: Icons.event_note,
                  message: 'Belum ada pemesanan masuk.',
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < terbaru.length; i++) ...[
                    if (i > 0) const Divider(height: 18),
                    _RecentBookingTile(booking: terbaru[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentBookingTile extends ConsumerWidget {
  const _RecentBookingTile({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () =>
            ref.read(mainNavIndexProvider.notifier).setTab(MainTab.booking),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.lightOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.namaTempat ?? 'Tempat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.namaTenant ?? 'Penyewa'} Â· '
                      '${formatDateString(booking.tanggalMulai)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatRupiah(booking.totalHarga),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: booking.status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'LUNAS' => (AppColors.sageTint, AppColors.sage),
      'MENUNGGU_PEMBAYARAN' => (AppColors.lightOrange, AppColors.primaryInk),
      'DIBATALKAN' => (
        AppColors.danger.withValues(alpha: 0.09),
        AppColors.danger,
      ),
      _ => (AppColors.surfaceMuted, AppColors.secondaryText),
    };

    final label = switch (status) {
      'MENUNGGU_PEMBAYARAN' => 'Menunggu Bayar',
      'LUNAS' => 'Lunas',
      'DIBATALKAN' => 'Dibatalkan',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880 ? 4 : 2;

        return ShimmerLoading(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 124,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const ShimmerBox(
              width: double.infinity,
              height: 116,
              radius: AppRadius.lg,
            ),
          ),
        );
      },
    );
  }
}

String _ringkas(num value) {
  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
  }
  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
  }
  return formatRupiah(value);
}
