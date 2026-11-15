import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Tab Booking — riwayat pemesanan dari `GET /bookings`.
///
/// Isi otomatis menyesuaikan role (dilakukan backend):
/// - **Penyewa**: daftar penyewaannya sendiri, bisa membatalkan yang
///   masih menunggu pembayaran.
/// - **Pemilik**: daftar pesanan masuk untuk tempat miliknya.
///
/// Pembayaran/E-Pass menyusul pada fitur berikutnya.
class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan pemesanan?'),
        content: const Text(
          'Pemesanan yang dibatalkan tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Batalkan Pesanan',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(bookingsProvider.notifier).cancel(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemesanan berhasil dibatalkan')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membatalkan pemesanan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final isHost = user?.role == UserModel.roleHost;
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: Text(isHost ? 'Pesanan Masuk' : 'Penyewaan Saya'),
      ),
      body: bookings.when(
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
              onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
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
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = items[index];

                return _BookingCard(
                  booking: booking,
                  isHost: isHost,
                  onCancel: booking.bisaDibatalkan && !isHost
                      ? () => _confirmCancel(context, ref, booking)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Kartu satu pemesanan.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isHost,
    this.onCancel,
  });

  final BookingModel booking;
  final bool isHost;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final pihakLain = isHost
        ? (booking.namaTenant ?? 'Penyewa')
        : (booking.namaTempat ?? 'Tempat');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w600,
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
          const SizedBox(height: 8),
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
              if (onCancel != null)
                TextButton(onPressed: onCancel, child: const Text('Batalkan')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge status pemesanan (MENUNGGU_PEMBAYARAN / LUNAS / DIBATALKAN).
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
        color: aktif ? AppColors.primaryOrange : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: aktif ? AppColors.white : AppColors.secondaryText,
        ),
      ),
    );
  }
}
