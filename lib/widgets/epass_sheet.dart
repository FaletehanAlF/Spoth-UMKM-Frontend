import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/services/payment_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../core/utils/format.dart';
import '../providers/auth_provider.dart';
import 'shimmer_loading.dart';

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
      if (token == null) {
        setState(() {
          _error = 'Sesi berakhir. Silakan masuk kembali.';
          _loading = false;
        });
        return;
      }

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
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const _SheetSkeleton()
            : _error != null
            ? _SheetError(message: _error!, onCobaLagi: _load)
            : _SheetIsi(hasil: _hasil!),
      ),
    );
  }
}

class _SheetIsi extends StatelessWidget {
  const _SheetIsi({required this.hasil});

  final EPassResult hasil;

  @override
  Widget build(BuildContext context) {
    final epass = hasil.epass;

    return SingleChildScrollView(
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
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'E-Pass',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      epass.namaTempat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _LencanaKode(kode: epass.kodeBooking),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: QrImageView(
                data: epass.kodeBooking,
                version: QrVersions.auto,
                size: 176,
                backgroundColor: AppColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.charcoal,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Tunjukkan kode ini di lokasi untuk verifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Column(
              children: [
                _BarisInfo(label: 'Penyewa', nilai: epass.namaTenant ?? '-'),
                _BarisInfo(label: 'Pemilik', nilai: epass.namaHost ?? '-'),
                _BarisInfo(label: 'Jenis usaha', nilai: epass.jenisUsaha),
                _BarisInfo(
                  label: 'Periode',
                  nilai:
                      '${formatDateString(epass.tanggalMulai)} – '
                      '${formatDateString(epass.tanggalSelesai)}',
                ),
                _BarisInfo(
                  label: 'Durasi',
                  nilai: '${epass.jumlahDurasi} ${epass.tipeDurasi}',
                ),
                _BarisInfo(
                  label: 'Lokasi',
                  nilai: '${epass.alamat}, ${epass.kecamatan}',
                ),
                _BarisInfo(
                  label: 'Total',
                  nilai: formatRupiah(epass.totalHarga),
                ),
                _BarisInfo(
                  label: 'Biaya admin',
                  nilai: formatRupiah(epass.adminFee),
                ),
                _BarisInfo(
                  label: 'Metode',
                  nilai: _metodeLabel(epass.metodePembayaran),
                ),
                _BarisInfo(label: 'Status', nilai: epass.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TeksEpass(teks: hasil.teksEpass),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LencanaKode extends StatelessWidget {
  const _LencanaKode({required this.kode});

  final String kode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        kode,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}

class _TeksEpass extends StatelessWidget {
  const _TeksEpass({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text(
          'Teks E-Pass',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        subtitle: const Text(
          'Bisa disalin atau dicetak',
          style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SelectableText(
              teks,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.message, required this.onCobaLagi});

  final String message;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_2,
            size: 40,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onCobaLagi,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryInk,
              side: const BorderSide(color: AppColors.neutralBorder),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: ShimmerLoading(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 90, height: 18),
            SizedBox(height: 8),
            ShimmerBox(width: 190, height: 12),
            SizedBox(height: 18),
            Center(child: ShimmerBox(width: 204, height: 204, radius: 16)),
            SizedBox(height: 18),
            ShimmerBox(width: double.infinity, height: 12),
            SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 12),
            SizedBox(height: 8),
            ShimmerBox(width: 220, height: 12),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
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
                height: 1.4,
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

String _metodeLabel(String? metode) {
  return switch (metode) {
    'DANA' => 'DANA',
    'OVO' => 'OVO',
    'GOPAY' => 'GoPay',
    'SHOPEEPAY' => 'ShopeePay',
    'SIMULASI' => 'Simulasi',
    'TRANSFER' => 'Transfer Bank',
    'QRIS' => 'QRIS',
    'TUNAI' => 'Tunai',
    _ => metode ?? '-',
  };
}
