import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _loading = true;
  String? _error;

  BookingModel? _booking;
  PaymentModel? _paymentAda;

  String _metode = 'SIMULASI';
  bool _membayar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
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
        _paymentAda = payment;
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

  Future<void> _bayar() async {
    if (_membayar) return;

    setState(() => _membayar = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final hasil = await ref
          .read(paymentServiceProvider)
          .payBooking(
            token: token,
            bookingId: widget.bookingId,
            metode: _metode,
          );

      if (!mounted) return;
      setState(() {
        _paymentAda = hasil;
        _booking = _booking != null
            ? BookingModel(
                id: _booking!.id,
                kodeBooking: hasil.kodeBooking,
                placeId: _booking!.placeId,
                tenantId: _booking!.tenantId,
                jenisUsaha: _booking!.jenisUsaha,
                tanggalMulai: _booking!.tanggalMulai,
                tanggalSelesai: _booking!.tanggalSelesai,
                jumlahDurasi: _booking!.jumlahDurasi,
                hargaSatuan: _booking!.hargaSatuan,
                totalHarga: _booking!.totalHarga,
                status: 'LUNAS',
                namaTempat: _booking!.namaTempat,
                kota: _booking!.kota,
                namaTenant: _booking!.namaTenant,
                namaHost: _booking!.namaHost,
                foto: _booking!.foto,
              )
            : _booking;
        _membayar = false;
      });

      await ref.read(bookingsProvider.notifier).refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _membayar = false);
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _membayar = false);
      _showSnack('Gagal memproses pembayaran. Coba lagi.');
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
      backgroundColor: AppColors.white,
      appBar: const SpothAppBar(title: Text('Pembayaran')),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: BookingListSkeleton(count: 3),
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

    final sudahLunas = booking.status == 'LUNAS';

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: sudahLunas
            ? _SuksesPembayaran(
                booking: booking,
                payment: _paymentAda,
                onLihatEPass: _bukaEPass,
                onSelesai: () => Navigator.of(context).pop(true),
              )
            : Column(
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
                            icon: Icons.payment_outlined,
                            title: 'Metode Pembayaran',
                          ),
                          const SizedBox(height: 12),
                          ..._pilihanMetode.map(
                            (pilihan) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MetodeOption(
                                pilihan: pilihan,
                                dipilih: _metode == pilihan.kode,
                                onTap: () =>
                                    setState(() => _metode = pilihan.kode),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(
                                Icons.info_outline,
                                size: 15,
                                color: AppColors.secondaryText,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Pembayaran ini simulasi dan tidak memindahkan uang asli.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        top: BorderSide(color: AppColors.softBorder),
                      ),
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
                                Expanded(
                                  child: Text(
                                    'Total Bayar',
                                    style: const TextStyle(
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
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Bayar Sekarang',
                              isLoading: _membayar,
                              height: 50,
                              borderRadius: 14,
                              onPressed: _bayar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PilihanMetode {
  const _PilihanMetode(this.kode, this.label, this.keterangan, this.icon);

  final String kode;
  final String label;
  final String keterangan;
  final IconData icon;
}

const _pilihanMetode = <_PilihanMetode>[
  _PilihanMetode(
    'TRANSFER',
    'Transfer Bank',
    'Simulasi transfer bank',
    Icons.account_balance_outlined,
  ),
  _PilihanMetode('QRIS', 'QRIS', 'Simulasi bayar dengan QR', Icons.qr_code_2),
];

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
                '${formatDateString(booking.tanggalMulai)} – '
                '${formatDateString(booking.tanggalSelesai)}',
          ),
          _BarisInfo(
            label: 'Lama Sewa',
            nilai: '${booking.jumlahDurasi} satuan durasi',
          ),
          _BarisInfo(
            label: 'Harga Satuan',
            nilai: formatRupiah(booking.hargaSatuan),
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
                  color: AppColors.primaryOrange,
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

class _MetodeOption extends StatelessWidget {
  const _MetodeOption({
    required this.pilihan,
    required this.dipilih,
    required this.onTap,
  });

  final _PilihanMetode pilihan;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dipilih ? AppColors.primaryOrange : AppColors.softBorder,
              width: dipilih ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: dipilih ? AppColors.lightOrange : null,
                  borderRadius: BorderRadius.circular(12),
                  border: dipilih
                      ? null
                      : Border.all(color: AppColors.softBorder),
                ),
                child: Icon(
                  pilihan.icon,
                  size: 22,
                  color: dipilih
                      ? AppColors.primaryOrange
                      : AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilihan.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: dipilih
                            ? AppColors.primaryOrange
                            : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pilihan.keterangan,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dipilih
                        ? AppColors.primaryOrange
                        : AppColors.softBorder,
                    width: 2,
                  ),
                ),
                child: dipilih
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
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
                      '${formatDateString(booking.tanggalMulai)} – '
                      '${formatDateString(booking.tanggalSelesai)}',
                ),
                _BarisInfo(label: 'Metode', nilai: payment?.metodeLabel ?? '-'),
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

class EPassSheet extends ConsumerStatefulWidget {
  const EPassSheet({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<EPassSheet> createState() => _EPassSheetState();
}

class _EPassSheetState extends ConsumerState<EPassSheet> {
  bool _loading = true;
  String? _error;
  EPassResult? _hasil;

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
      if (token == null) return;

      final hasil = await ref
          .read(paymentServiceProvider)
          .getEPass(token: token, bookingId: widget.bookingId);

      if (!mounted) return;
      setState(() {
        _hasil = hasil;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat E-Pass';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                ),
              )
            : _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.softBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'E-Pass Pemesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _hasil?.teksEpass ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          height: 1.55,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _BarisInfo(
                      label: 'Penyewa',
                      nilai: _hasil?.epass.namaTenant ?? '-',
                    ),
                    _BarisInfo(
                      label: 'Pemilik',
                      nilai: _hasil?.epass.namaHost ?? '-',
                    ),
                    _BarisInfo(
                      label: 'Alamat',
                      nilai:
                          '${_hasil?.epass.alamat ?? '-'}, '
                          '${_hasil?.epass.kota ?? '-'}',
                    ),
                    _BarisInfo(
                      label: 'Metode',
                      nilai: switch (_hasil?.epass.metodePembayaran) {
                        'SIMULASI' => 'Simulasi',
                        'TRANSFER' => 'Transfer Bank',
                        'QRIS' => 'QRIS',
                        'TUNAI' => 'Tunai',
                        _ => _hasil?.epass.metodePembayaran ?? '-',
                      },
                    ),
                    _BarisInfo(
                      label: 'Status',
                      nilai: _hasil?.epass.status ?? '-',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
