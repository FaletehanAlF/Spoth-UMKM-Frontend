import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/place_grid_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final isHost = user?.role == UserModel.roleHost;
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: bookings.when(
          loading: () => const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTitleSkeleton(subtitleWidth: 170),
                SizedBox(height: 18),
                BookingListSkeleton(count: 4),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.wifi_off,
                title: 'Gagal memuat pemesanan',
                message: 'Periksa koneksi internet Anda lalu coba lagi.',
                actionLabel: 'Coba Lagi',
                onAction: () => ref.read(bookingsProvider.notifier).refresh(),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primaryDeep,
                onRefresh: () =>
                    ref.read(bookingsProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.lightOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_note,
                                  size: 28,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada penyewaan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isHost
                                    ? 'Penyewaan untuk tempat Anda akan tampil di sini.'
                                    : 'Pilih tempat di Beranda lalu tekan "Sewa Tempat Ini".',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryDeep,
              onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final duaKolom = constraints.maxWidth >= 700;
                    final lebarKartu = duaKolom
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final booking in items)
                          SizedBox(
                            width: lebarKartu,
                            child: _BookingCard(
                              booking: booking,
                              isHost: isHost,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking, required this.isHost});

  final BookingModel booking;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pihakLain = isHost
        ? (booking.namaTenant ?? 'Penyewa')
        : (booking.namaTempat ?? 'Tempat');
    final belumBayar = !isHost && booking.status == 'MENUNGGU_PEMBAYARAN';

    return InkWell(
      onTap: () => belumBayar
          ? context.push('/payment?id=${booking.id}')
          : context.push('/place-detail?id=${booking.placeId}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.softBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: booking.firstFoto != null
                        ? Image.network(
                            booking.firstFoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const PlacePhotoPlaceholder(),
                          )
                        : const PlacePhotoPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pihakLain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _TanggalBaris(
                        ikon: Icons.calendar_today_rounded,
                        teks: formatDateString(booking.tanggalMulai),
                      ),
                      const SizedBox(height: 3),
                      _TanggalBaris(
                        ikon: Icons.event_available_rounded,
                        teks: formatDateString(booking.tanggalSelesai),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusLabel(status: booking.status),
              ],
            ),
            if (belumBayar) ...[
              const SizedBox(height: 10),
              const _CatatanBelumBayar(),
            ],
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_TautanDetail()],
            ),
          ],
        ),
      ),
    );
  }
}

class _TanggalBaris extends StatelessWidget {
  const _TanggalBaris({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 12, color: AppColors.secondaryText),
        const SizedBox(width: 6),
        Text(
          teks,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _CatatanBelumBayar extends StatelessWidget {
  const _CatatanBelumBayar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.payment_outlined,
            size: 18,
            color: AppColors.primaryDeep,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum membayar. Ketuk kartu ini untuk membuka halaman pembayaran.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, latar, teks) = switch (status) {
      'LUNAS' => ('Disewa', AppColors.sageTint, AppColors.sage),
      'MENUNGGU_PEMBAYARAN' => (
        'Menunggu Bayar',
        AppColors.lightOrange,
        AppColors.primaryDeep,
      ),
      'DIBATALKAN' => (
        'Dibatalkan',
        AppColors.surfaceMuted,
        AppColors.secondaryText,
      ),
      _ => (status, AppColors.surfaceMuted, AppColors.secondaryText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
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

class _TautanDetail extends StatelessWidget {
  const _TautanDetail();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lihat Detail',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryInk,
          ),
        ),
        SizedBox(width: 2),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.primaryInk,
        ),
      ],
    );
  }
}
