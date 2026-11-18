import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/booking_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/riwayat_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/epass_sheet.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  bool _loading = true;
  String? _error;
  List<BookingModel> _items = const <BookingModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final bookings = await ref
          .read(bookingServiceProvider)
          .listBookings(token: token);

      final lunas = bookings.where((b) => b.status == 'LUNAS').toList();

      if (!mounted) return;
      setState(() {
        _items = lunas;
        _loading = false;
      });

      await ref.read(riwayatBadgeProvider.notifier).markAllSeen();
      await ref.read(riwayatBadgeProvider.notifier).refresh();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat riwayat';
        _loading = false;
      });
    }
  }

  void _bukaEPass(BookingModel booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EPassSheet(bookingId: booking.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final isHost = user?.role == UserModel.roleHost;

    final page = Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: Text(isHost ? 'Riwayat Penyewaan' : 'Riwayat Saya'),
        actions: const [],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: BookingListSkeleton(count: 4),
            )
          : _error != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.wifi_off,
                  title: _error!,
                  message: 'Periksa koneksi internet Anda lalu coba lagi.',
                  actionLabel: 'Coba Lagi',
                  onAction: _load,
                ),
              ),
            )
          : _items.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmptyState(
                      icon: Icons.history,
                      title: isHost
                          ? 'Belum ada tempat yang disewa'
                          : 'Belum ada riwayat penyewaan',
                      message: isHost
                          ? 'Tempat Anda yang berhasil disewa (lunas) akan '
                                'tampil di sini sebagai riwayat.'
                          : 'Penyewaan Anda yang sudah lunas akan tampil di '
                                'sini sebagai riwayat.',
                      actionLabel: isHost
                          ? 'Lihat Pesanan Masuk'
                          : 'Cari Tempat',
                      onAction: () {
                        ref
                            .read(mainNavIndexProvider.notifier)
                            .setTab(isHost ? MainTab.booking : MainTab.tempat);
                        context.go('/home');
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHost
                                  ? 'Riwayat hanya menampilkan penyewaan yang '
                                        'sudah lunas (dibayar). Pesanan yang '
                                        'masih menunggu bayar ada di menu Booking.'
                                  : 'Riwayat hanya menampilkan penyewaan yang '
                                        'sudah lunas. Pesanan yang masih '
                                        'menunggu bayar ada di tab Booking.',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryOrange,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = _items[index];
                  return _RiwayatCard(
                    booking: booking,
                    isHost: isHost,
                    onLihatEPass: () => _bukaEPass(booking),
                  );
                },
              ),
            ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.booking, child: page);
  }
}

class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({
    required this.booking,
    required this.isHost,
    required this.onLihatEPass,
  });

  final BookingModel booking;
  final bool isHost;
  final VoidCallback onLihatEPass;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Lunas',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          if (isHost) ...[
            const SizedBox(height: 2),
            Text(
              booking.namaTempat ?? 'Tempat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
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
              OutlinedButton.icon(
                onPressed: onLihatEPass,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryOrange,
                  side: const BorderSide(color: AppColors.primaryOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.qr_code_2, size: 16),
                label: const Text('E-Pass'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
