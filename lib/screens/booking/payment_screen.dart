import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/api_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/riwayat_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/epass_sheet.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;

  BookingModel? _booking;
  PaymentModel? _payment;

  bool _memproses = false;
  bool _memeriksa = false;

  bool _pembayaranDibuka = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_pembayaranDibuka || !mounted) {
      return;
    }

    _pembayaranDibuka = false;
    setState(() => _memproses = false);
    _periksaStatus();
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final booking = await ref
          .read(bookingServiceProvider)
          .getBooking(token: token, id: widget.bookingId);

      PaymentModel? payment;
      try {
        payment = await ref
            .read(paymentServiceProvider)
            .getPayment(token: token, bookingId: widget.bookingId);
      } on ApiException {
        payment = null;
      }

      if (!mounted) return;
      setState(() {
        _booking = booking;
        _payment = payment;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data pembayaran';
        _loading = false;
      });
    }
  }

  Future<void> _buatTransaksi({bool paksaBaru = false}) async {
    if (_memproses) return;

    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    setState(() => _memproses = true);

    try {
      final payment = await ref
          .read(paymentServiceProvider)
          .payBooking(
            token: token,
            bookingId: widget.bookingId,
            force: paksaBaru,
          );

      if (!mounted) return;
      setState(() => _payment = payment);

      await _bukaLinkPembayaran(payment);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _memproses = false);
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _memproses = false);
      _showSnack('Gagal membuat transaksi pembayaran. Coba lagi.');
    }
  }

  Future<void> _bukaUlangPembayaran() async {
    final payment = _payment;
    if (payment == null || _memproses) return;

    setState(() => _memproses = true);
    await _bukaLinkPembayaran(payment);
  }

  /// Membuat transaksi Snap baru saat halaman pembayaran lama sudah
  /// kedaluwarsa. Transaksi lama otomatis ditutup oleh backend.
  Future<void> _buatTransaksiBaru() => _buatTransaksi(paksaBaru: true);

  Future<void> _bukaLinkPembayaran(PaymentModel payment) async {
    final alamat = payment.redirectUrl;
    if (alamat == null || alamat.isEmpty) {
      if (mounted) setState(() => _memproses = false);
      _showSnack('Link pembayaran belum tersedia. Coba lagi sebentar.');
      return;
    }

    final uri = Uri.tryParse(alamat);
    if (uri == null) {
      if (mounted) setState(() => _memproses = false);
      _showSnack('Link pembayaran tidak valid.');
      return;
    }

    _pembayaranDibuka = true;
    final terbuka = await _bukaPembayaran(uri);

    if (!terbuka) {
      _pembayaranDibuka = false;
    }
    if (mounted) setState(() => _memproses = false);
    if (!terbuka && mounted) {
      _showSnack('Halaman pembayaran tidak bisa dibuka. Periksa browser Anda.');
    }
  }

  /// Membuka halaman Midtrans di dalam aplikasi.
  ///
  /// Android memakai Chrome Custom Tabs dan iOS memakai SFSafariViewController,
  /// sehingga pengguna tidak dilempar ke aplikasi browser terpisah. Jika
  /// perangkat tidak mendukung, halaman dibuka di browser biasa.
  Future<bool> _bukaPembayaran(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        return true;
      }
    } catch (_) {
      // Perangkat tidak punya browser yang mendukung mode dalam aplikasi.
    }

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _periksaStatus() async {
    if (!mounted || _memeriksa) return;

    final token = ref.read(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    setState(() => _memeriksa = true);

    try {
      final payment = await ref
          .read(paymentServiceProvider)
          .syncPayment(token: token, bookingId: widget.bookingId);

      if (!mounted) return;
      setState(() => _payment = payment);

      await ref.read(bookingsProvider.notifier).refresh();
      await ref.read(riwayatBadgeProvider.notifier).refresh();

      await _load();

      if (!mounted) return;
      final terbayar = _booking?.status == 'LUNAS';
      _showSnack(
        terbayar
            ? 'Pembayaran berhasil. E-Pass Anda sudah terbit.'
            : 'Pembayaran belum masuk. Selesaikan dulu di halaman Midtrans.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal memeriksa status pembayaran. Coba lagi.');
    } finally {
      if (mounted) setState(() => _memeriksa = false);
    }
  }

  void _bukaEPass() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EPassSheet(bookingId: widget.bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(title: Text('Pembayaran')),
      body: _loading
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppWidth.list),
                child: const SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: BookingListSkeleton(count: 3),
                ),
              ),
            )
          : _error != null
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppWidth.list),
                child: Center(
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
                ),
              ),
            )
          : _buildIsi(),
    );

    return SpothSidebarScaffold(activeTab: MainTab.booking, child: page);
  }

  Widget _buildIsi() {
    final booking = _booking;

    if (booking == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Pemesanan tidak ditemukan',
          message: 'Pemesanan yang dimaksud tidak tersedia.',
        ),
      );
    }

    if (booking.status == 'DIBATALKAN') {
      return const Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.cancel_outlined,
            title: 'Pemesanan sudah dibatalkan',
            message: 'Pemesanan ini tidak dapat dibayar lagi.',
          ),
        ),
      );
    }

    if (booking.status == 'LUNAS') {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _SuksesPembayaran(
            booking: booking,
            payment: _payment,
            onLihatEPass: _bukaEPass,
            onSelesai: () => Navigator.of(context).pop(true),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RingkasanCard(booking: booking),
                    const SizedBox(height: 16),
                    const _SectionHeader(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Metode Pembayaran',
                    ),
                    const SizedBox(height: 12),
                    _KartuMidtrans(payment: _payment),
                    const SizedBox(height: 10),
                    const _Catatan(
                      'Pembayaran diproses oleh Midtrans. Pilih QRIS, transfer '
                      'bank, e-wallet, atau kartu di halaman pembayaran. '
                      'Setelah selesai, kembali ke aplikasi untuk memeriksa status.',
                    ),
                    if (_payment != null && _payment!.masihMenunggu) ...[
                      const SizedBox(height: 12),
                      _RingkasanTransaksi(payment: _payment!),
                    ],
                  ],
                ),
              ),
            ),
            _BilahAksi(
              booking: booking,
              payment: _payment,
              memproses: _memproses,
              memeriksa: _memeriksa,
              onBayar: () => _buatTransaksi(),
              onBukaUlang: _bukaUlangPembayaran,
              onBuatUlang: _buatTransaksiBaru,
              onPeriksa: _periksaStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuMidtrans extends StatelessWidget {
  const _KartuMidtrans({required this.payment});

  final PaymentModel? payment;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 22,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midtrans',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'QRIS, transfer bank, e-wallet, kartu',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (payment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                payment!.statusLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingkasanTransaksi extends StatelessWidget {
  const _RingkasanTransaksi({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final kedaluwarsa = payment.expiredAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaksi sudah dibuat',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selesaikan pembayaran, lalu tekan "Cek Status" agar E-Pass terbit.',
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
          ),
          if (kedaluwarsa != null) ...[
            const SizedBox(height: 6),
            Text(
              'Batas akhir: ${formatDateString(kedaluwarsa.toIso8601String())} ${_jam(kedaluwarsa)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _jam(DateTime waktu) {
    final lokal = waktu.toLocal();

    return '${lokal.hour.toString().padLeft(2, '0')}:'
        '${lokal.minute.toString().padLeft(2, '0')}';
  }
}

class _BilahAksi extends StatelessWidget {
  const _BilahAksi({
    required this.booking,
    required this.payment,
    required this.memproses,
    required this.memeriksa,
    required this.onBayar,
    required this.onBukaUlang,
    required this.onBuatUlang,
    required this.onPeriksa,
  });

  final BookingModel booking;
  final PaymentModel? payment;
  final bool memproses;
  final bool memeriksa;
  final VoidCallback onBayar;
  final VoidCallback onBukaUlang;
  final VoidCallback onBuatUlang;
  final VoidCallback onPeriksa;

  @override
  Widget build(BuildContext context) {
    final adaTransaksi = payment != null && payment!.masihMenunggu;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Bayar',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatRupiah(booking.totalHarga),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (adaTransaksi) ...[
                PrimaryButton(
                  label: 'Buka Halaman Pembayaran',
                  isLoading: memproses,
                  height: 50,
                  borderRadius: 14,
                  onPressed: onBukaUlang,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: memeriksa ? null : onPeriksa,
                  icon: memeriksa
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Cek Status Pembayaran'),
                ),
                TextButton(
                  onPressed: memproses ? null : onBuatUlang,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Buat Ulang Pembayaran'),
                ),
              ] else
                PrimaryButton(
                  label: 'Bayar dengan Midtrans',
                  isLoading: memproses,
                  height: 50,
                  borderRadius: 14,
                  onPressed: onBayar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 15,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            teks,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingkasanCard extends StatelessWidget {
  const _RingkasanCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Ringkasan Pemesanan',
          ),
          const SizedBox(height: 14),
          Text(
            booking.namaTempat ?? 'Tempat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            booking.jenisUsaha,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          _BarisInfo(
            label: 'Tanggal',
            nilai:
                '${formatDateString(booking.tanggalMulai)} - '
                '${formatDateString(booking.tanggalSelesai)}',
          ),
          _BarisInfo(
            label: 'Harga Sewa',
            nilai: formatRupiah(booking.hargaSatuan),
          ),
          _BarisInfo(
            label: 'Biaya Admin',
            nilai: formatRupiah(booking.adminFee),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.softBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(booking.totalHarga),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuksesPembayaran extends StatelessWidget {
  const _SuksesPembayaran({
    required this.booking,
    required this.payment,
    required this.onLihatEPass,
    required this.onSelesai,
  });

  final BookingModel booking;
  final PaymentModel? payment;
  final VoidCallback onLihatEPass;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    final kode = booking.kodeBooking ?? payment?.kodeBooking ?? '-';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pembayaran Berhasil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kode booking Anda',
            style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Salin kode booking',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.primaryOrange,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: kode));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode booking disalin')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  icon: Icons.receipt_long_outlined,
                  title: 'Rincian',
                ),
                const SizedBox(height: 14),
                _BarisInfo(label: 'Tempat', nilai: booking.namaTempat ?? '-'),
                _BarisInfo(
                  label: 'Periode',
                  nilai:
                      '${formatDateString(booking.tanggalMulai)} - '
                      '${formatDateString(booking.tanggalSelesai)}',
                ),
                _BarisInfo(
                  label: 'Metode',
                  nilai: payment?.metodeLabel ?? 'Midtrans',
                ),
                _BarisInfo(
                  label: 'Biaya Admin',
                  nilai: formatRupiah(booking.adminFee),
                ),
                _BarisInfo(
                  label: 'Total Bayar',
                  nilai: formatRupiah(booking.totalHarga),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onLihatEPass,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
              side: const BorderSide(color: AppColors.primaryOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Lihat E-Pass'),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Selesai',
            height: 50,
            borderRadius: 14,
            onPressed: onSelesai,
          ),
        ],
      ),
    );
  }
}
