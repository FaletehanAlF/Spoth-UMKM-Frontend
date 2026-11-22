import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Dashboard pemilik tempat.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const SpothAppBar(
        title: Text('Dashboard'),
        showRiwayat: true,
        showNotification: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.ultra,
          AppSpacing.ultra,
          AppSpacing.ultra,
          AppSpacing.mega,
        ),
        children: [
          _WelcomeHeader(user: ref.watch(authNotifierProvider).user),
          const SizedBox(height: AppSpacing.xl),
          _summaryBody(ref: ref),
        ],
      ),
    );
  }
}

Widget _summaryBody({required WidgetRef ref}) {
  final summary = ref.watch(hostSummaryProvider);

  return summary.when(
    loading: () => const _KpiSkeleton(),
    error: (error, _) => EmptyState(
      icon: Icons.error_outline,
      title: 'Gagal memuat ringkasan',
      message: 'Periksa koneksi internet Anda lalu tarik ke bawah untuk mencoba lagi.',
      actionLabel: 'Coba Lagi',
      onAction: () => ref.read(hostSummaryProvider.notifier).refresh(),
    ),
    data: (value) {
      if (value == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NetRevenueCard(summary: value),
          const SizedBox(height: AppSpacing.xxl),
          _KpiGrid(summary: value),
          const SizedBox(height: AppSpacing.xxl),
          _QuickActions(),
          const SizedBox(height: AppSpacing.xxl),
          _RecentBookingsSection(),
        ],
      );
    },
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final saapaan = namaDepan(user?.nama);

    return Row(
      children: [
        if (user?.foto != null && user!.foto!.isNotEmpty)
          ClipOval(
            child: Image.network(
              user!.foto!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _AvatarFallback(),
            ),
          )
        else
          const _AvatarFallback(),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (saapaan != null)
                Text(
                  'Halo, $saapaan',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ringkasan Usaha',
                style: AppFonts.heading(
                  fontSize: 26,
                  weight: 700,
                  height: 1.1,
                  color: AppColors.charcoal,
                ),
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 24,
        color: AppColors.primaryInk,
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
        final width = constraints.maxWidth;
        final columns = width >= 880
            ? 4
            : width >= 480
            ? 2
            : 1;
        final gap = width >= 480 ? AppSpacing.xxl : AppSpacing.xl;

        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.xxl,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: columns == 1
                    ? double.infinity
                    : (width - gap * (columns - 1)) / columns,
                child: _KpiCard(data: items[i]),
              ),
          ],
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 18, color: data.tone),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: AppFonts.heading(
                fontSize: 20,
                weight: 700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
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
              Expanded(
                child: Text(
                  'Pendapatan Bersih',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                formatRupiah(bersih),
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(color: AppColors.primaryDeep),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Total yang datang setelah komisi platform.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _RevenueRow(
            label: 'Pendapatan Tercatat',
            value: pendapatan,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(height: AppSpacing.xs),
          _RevenueRow(label: 'Komisi', value: komisi, color: AppColors.danger),
          const SizedBox(height: AppSpacing.xs),
          _RevenueRow(
            label: 'Pendapatan Bersih',
            value: bersih.toDouble(),
            color: AppColors.sage,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: AppSpacing.md),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatRupiah(value),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pindahTab(MainTab tab) {
      ref.read(mainNavIndexProvider.notifier).setTab(tab);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aksi Cepat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.storefront_outlined,
                  title: 'Kelola Tempat',
                  subtitle: 'Atur tempat & ketersediaan',
                  onTap: () => pindahTab(MainTab.kelolaTempat),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
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
      color: AppColors.lightOrange,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryDeep),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
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
              Expanded(
                child: Text(
                  'Pemesanan Terbaru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(mainNavIndexProvider.notifier)
                    .setTab(MainTab.booking),
                child: Text(
                  'Lihat Semua',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ShimmerBox(
                width: double.infinity,
                height: 60,
                radius: AppRadius.lg,
              ),
            ),
            error: (error, _) => _InlineMessage(
              icon: Icons.wifi_off,
              message: 'Gagal memuat pemesanan.',
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
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.softBorder),
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

class _RecentBookingTile extends StatelessWidget {
  const _RecentBookingTile({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.namaTempat ?? 'Tempat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${booking.namaTenant ?? 'Penyewa'} · ${formatDateString(booking.tanggalMulai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(booking.totalHarga),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _StatusBadge(status: booking.status),
            ],
          ),
        ],
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
        AppColors.danger.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (onAction != null)
            TextButton(onPressed: onAction, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Row(
            children: [
              const ShimmerBox(width: 80, height: 60, radius: AppRadius.lg),
              const SizedBox(width: AppSpacing.xxl),
              const Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 60,
                  radius: AppRadius.lg,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              const Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 60,
                  radius: AppRadius.lg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ],
    );
  }
}
