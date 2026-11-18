import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/payment_service.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

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
                        'DANA' => 'DANA',
                        'OVO' => 'OVO',
                        'GOPAY' => 'GoPay',
                        'SHOPEEPAY' => 'ShopeePay',
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
