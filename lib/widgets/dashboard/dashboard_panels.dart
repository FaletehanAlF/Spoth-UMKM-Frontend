import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../shimmer_loading.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pindah(MainTab tab) {
      ref.read(mainNavIndexProvider.notifier).setTab(tab);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final lebar = constraints.maxWidth;
        final duaKolom = lebar >= 560;
        final lebarItem = duaKolom ? (lebar - AppSpacing.lg) / 2 : lebar;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: lebarItem,
              child: _Aksi(
                ikon: Icons.storefront_outlined,
                judul: 'Kelola Tempat',
                keterangan: 'Tambah dan atur tempat usaha',
                onTap: () => pindah(MainTab.kelolaTempat),
              ),
            ),
            SizedBox(
              width: lebarItem,
              child: _Aksi(
                ikon: Icons.receipt_long_outlined,
                judul: 'Riwayat Penyewaan',
                keterangan: 'Pantau status setiap sewa',
                onTap: () => pindah(MainTab.booking),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Aksi extends StatelessWidget {
  const _Aksi({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.onTap,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Icon(ikon, size: 20, color: AppColors.primaryDeep),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentBookings extends ConsumerWidget {
  const RecentBookings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    void bukaSemua() {
      ref.read(mainNavIndexProvider.notifier).setTab(MainTab.booking);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
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
                  'Pemesanan Terbaru',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              TextButton(
                onPressed: bukaSemua,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ShimmerBox(
                width: double.infinity,
                height: 56,
                radius: AppRadius.md,
              ),
            ),
            error: (error, _) => _Pesan(
              ikon: Icons.wifi_off,
              teks: 'Gagal memuat pemesanan.',
              aksi: 'Coba lagi',
              onAksi: () => ref.read(bookingsProvider.notifier).refresh(),
            ),
            data: (items) {
              final terbaru = items.take(3).toList();

              if (terbaru.isEmpty) {
                return const _Pesan(
                  ikon: Icons.event_note_outlined,
                  teks: 'Belum ada pemesanan masuk.',
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < terbaru.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.softBorder),
                    _BarisPemesanan(booking: terbaru[i]),
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

class _BarisPemesanan extends StatelessWidget {
  const _BarisPemesanan({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.namaTempat ?? 'Tempat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.namaTenant ?? 'Penyewa'} · '
                  '${formatDateString(booking.tanggalMulai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(booking.totalHarga),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              _LencanaStatus(status: booking.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _LencanaStatus extends StatelessWidget {
  const _LencanaStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (latar, teks, label) = switch (status) {
      'LUNAS' => (AppColors.sageTint, AppColors.success, 'Lunas'),
      'MENUNGGU_PEMBAYARAN' => (
        AppColors.lightOrange,
        AppColors.primaryInk,
        'Menunggu bayar',
      ),
      'DIBATALKAN' => (
        AppColors.danger.withValues(alpha: 0.1),
        AppColors.danger,
        'Dibatalkan',
      ),
      _ => (AppColors.surfaceMuted, AppColors.secondaryText, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: teks,
        ),
      ),
    );
  }
}

class _Pesan extends StatelessWidget {
  const _Pesan({
    required this.ikon,
    required this.teks,
    this.aksi,
    this.onAksi,
  });

  final IconData ikon;
  final String teks;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (aksi != null && onAksi != null)
            TextButton(onPressed: onAksi, child: Text(aksi!)),
        ],
      ),
    );
  }
}
