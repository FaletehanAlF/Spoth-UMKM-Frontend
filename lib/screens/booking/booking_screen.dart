import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
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
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: Text(isHost ? 'Pesanan Masuk' : 'Penyewaan Saya'),
        actions: const [NotificationIconButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: BookingListSkeleton(count: 4),
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
                  color: AppColors.primaryOrange,
                  onRefresh: () =>
                      ref.read(bookingsProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyState(
                          icon: Icons.event_note,
                          title: isHost
                              ? 'Belum ada pesanan masuk'
                              : 'Belum ada penyewaan',
                          message: isHost
                              ? 'Pesanan untuk tempat Anda akan tampil di sini.'
                              : 'Pilih tempat di Beranda lalu tekan "Sewa Tempat Ini".',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryOrange,
                onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = items[index];

                    return _BookingCard(booking: booking, isHost: isHost);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.isHost});

  final BookingModel booking;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final pihakLain = isHost
        ? (booking.namaTenant ?? 'Penyewa')
        : (booking.namaTempat ?? 'Tempat');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pihakLain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kode: ${booking.kodeBooking ?? '-'} • ${booking.jenisUsaha}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${formatDateString(booking.tanggalMulai)} – '
                  '${formatDateString(booking.tanggalSelesai)} '
                  '(${booking.jumlahDurasi} satuan durasi)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatRupiah(booking.totalHarga),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              _StatusLabel(status: booking.status),
            ],
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
    if (status != 'MENUNGGU_PEMBAYARAN') {
      return const SizedBox.shrink();
    }

    return const Text(
      'Menunggu pembayaran',
      style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'MENUNGGU_PEMBAYARAN' => 'Menunggu Bayar',
      'LUNAS' => 'Lunas',
      'DIBATALKAN' => 'Dibatalkan',
      _ => status,
    };

    final aktif = status == 'MENUNGGU_PEMBAYARAN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: aktif ? AppColors.primaryOrange : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: aktif ? AppColors.white : AppColors.charcoal,
        ),
      ),
    );
  }
}
