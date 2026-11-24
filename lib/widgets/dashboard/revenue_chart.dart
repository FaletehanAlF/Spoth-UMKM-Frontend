import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';

/// Grafik garis pendapatan enam bulan terakhir.
///
/// Ketuk salah satu titik untuk melihat nilai bulannya di bagian atas.
class RevenueChart extends StatefulWidget {
  const RevenueChart({super.key, required this.data});

  final List<MonthlyRevenueModel> data;

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  int _dipilih = -1;

  @override
  void didUpdateWidget(covariant RevenueChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.length != widget.data.length) {
      _dipilih = -1;
    }
  }

  void _pilih(double dx, double lebar) {
    if (widget.data.isEmpty) return;

    final jumlah = widget.data.length;
    final langkah = jumlah <= 1 ? 0.0 : lebar / (jumlah - 1);
    final posisi = langkah == 0 ? 0 : (dx / langkah).round();
    final index = posisi.clamp(0, jumlah - 1);

    setState(() => _dipilih = index);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final terpilih = _dipilih >= 0 && _dipilih < data.length
        ? data[_dipilih]
        : null;
    final tertinggi = data.fold<double>(0, (a, b) => b.pendapatan > a ? b.pendapatan : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: terpilih == null
              ? Text(
                  tertinggi == 0
                      ? 'Belum ada pendapatan pada periode ini'
                      : 'Ketuk titik untuk melihat nilai bulan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                )
              : Text(
                  '${formatRupiahBulan(terpilih.bulan)} · ${formatRupiah(terpilih.pendapatan)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final lebar = constraints.maxWidth;

            return GestureDetector(
              key: const ValueKey('grafik-pendapatan'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (detail) => _pilih(detail.localPosition.dx, lebar),
              child: SizedBox(
                height: 168,
                width: lebar,
                child: CustomPaint(
                  painter: _RevenuePainter(
                    data: data,
                    indeksDipilih: _dipilih,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RevenuePainter extends CustomPainter {
  _RevenuePainter({required this.data, required this.indeksDipilih});

  final List<MonthlyRevenueModel> data;
  final int indeksDipilih;

  double _x(int index, double lebar) {
    if (data.length <= 1) return lebar / 2;
    return lebar * index / (data.length - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const atas = 14.0;
    const bawah = 26.0;
    final tinggi = (size.height - atas - bawah).clamp(1.0, double.infinity);
    final dasar = size.height - bawah;

    var maksimum = 0.0;
    for (final item in data) {
      if (item.pendapatan > maksimum) maksimum = item.pendapatan;
    }
    final puncak = maksimum == 0 ? 1.0 : maksimum;

    double y(double nilai) => atas + tinggi * (1 - nilai / puncak);

    final titik = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(_x(i, size.width), y(data[i].pendapatan)),
    ];

    canvas.drawLine(
      Offset(0, dasar),
      Offset(size.width, dasar),
      Paint()
        ..color = AppColors.softBorder
        ..strokeWidth = 1,
    );

    if (titik.length > 1) {
      final garis = Path()..moveTo(titik.first.dx, titik.first.dy);
      for (var i = 1; i < titik.length; i++) {
        final sebelum = titik[i - 1];
        final sekarang = titik[i];
        final tengah = (sebelum.dx + sekarang.dx) / 2;
        garis.cubicTo(tengah, sebelum.dy, tengah, sekarang.dy, sekarang.dx, sekarang.dy);
      }

      final bidang = Path.from(garis)
        ..lineTo(titik.last.dx, dasar)
        ..lineTo(titik.first.dx, dasar)
        ..close();

      canvas.drawPath(
        bidang,
        Paint()..color = AppColors.primaryDeep.withValues(alpha: 0.06),
      );
      canvas.drawPath(
        garis,
        Paint()
          ..color = AppColors.primaryDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < titik.length; i++) {
      final aktif = i == indeksDipilih;
      canvas.drawCircle(
        titik[i],
        aktif ? 5.5 : 3.5,
        Paint()..color = AppColors.white,
      );
      canvas.drawCircle(
        titik[i],
        aktif ? 5.5 : 3.5,
        Paint()
          ..color = AppColors.primaryDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      _tulis(
        canvas,
        data[i].labelBulan,
        Offset(titik[i].dx, dasar + 8),
        aktif: aktif,
      );
    }
  }

  void _tulis(
    Canvas canvas,
    String teks,
    Offset posisi, {
    bool aktif = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: teks,
        style: TextStyle(
          fontSize: 11,
          fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
          color: aktif ? AppColors.primaryInk : AppColors.secondaryText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(posisi.dx - painter.width / 2, posisi.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _RevenuePainter oldDelegate) {
    return oldDelegate.indeksDipilih != indeksDipilih ||
        oldDelegate.data.length != data.length;
  }
}

class RevenueSection extends StatelessWidget {
  const RevenueSection({super.key, required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final bulanan = summary.pendapatanBulanan ?? const <MonthlyRevenueModel>[];
    final terakhir = bulanan.isEmpty ? null : bulanan.last;
    final sebelumnya = bulanan.length > 1
        ? bulanan[bulanan.length - 2]
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Pendapatan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            terakhir == null
                ? 'Belum ada data bulanan'
                : 'Pendapatan bulan ${formatRupiahBulan(terakhir.bulan)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatRupiah(terakhir?.pendapatan ?? 0),
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColors.charcoal,
                ),
              ),
              if (terakhir != null && sebelumnya != null)
                _TrendBadge(sekarang: terakhir, sebelumnya: sebelumnya),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          RevenueChart(data: bulanan),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.softBorder),
          const SizedBox(height: AppSpacing.lg),
          _Baris(
            label: 'Total dibayar tenant',
            nilai: summary.totalPendapatan + summary.totalKomisi,
          ),
          const SizedBox(height: AppSpacing.sm),
          _Baris(
            label: 'Biaya admin platform',
            nilai: summary.totalKomisi,
            warna: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.sekarang, required this.sebelumnya});

  final MonthlyRevenueModel sekarang;
  final MonthlyRevenueModel sebelumnya;

  @override
  Widget build(BuildContext context) {
    final selisih = sekarang.pendapatan - sebelumnya.pendapatan;

    if (selisih == 0) {
      return const Text(
        'Sama dengan bulan lalu',
        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
      );
    }

    final naik = selisih > 0;
    final persen = sebelumnya.pendapatan > 0
        ? (selisih.abs() / sebelumnya.pendapatan * 100).round()
        : null;
    final teks = persen == null
        ? (naik ? 'Naik bulan ini' : 'Turun bulan ini')
        : '${naik ? 'Naik' : 'Turun'} $persen%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          naik ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 15,
          color: naik ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(width: 4),
        Text(
          teks,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: naik ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.nilai, this.warna});

  final String label;
  final double nilai;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          formatRupiah(nilai),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: warna ?? AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
