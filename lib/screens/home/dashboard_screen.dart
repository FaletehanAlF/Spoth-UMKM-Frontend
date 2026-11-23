import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

/// Dashboard pemilik tempat.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const SpothAppBar(
        title: Text('Dashboard'),
        showRiwayat: true,
        showNotification: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppWidth.page),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.ultra,
              AppSpacing.ultra,
              AppSpacing.ultra,
              AppSpacing.mega,
            ),
            children: [
              _WelcomeHeader(user: ref.watch(authNotifierProvider).user),
              const SizedBox(height: AppSpacing.xl),
              _summaryBody(ref: ref),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _summaryBody({required WidgetRef ref}) {
  final summary = ref.watch(hostSummaryProvider);

  return summary.when(
    loading: () => const _KpiSkeleton(),
    error: (error, _) => EmptyState(
      icon: Icons.error_outline,
      title: 'Gagal memuat ringkasan',
      message: 'Periksa koneksi internet Anda lalu tarik ke bawah untuk mencoba lagi.',
      actionLabel: 'Coba Lagi',
      onAction: () => ref.read(hostSummaryProvider.notifier).refresh(),
    ),
    data: (value) {
      if (value == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiGrid(summary: value),
          const SizedBox(height: AppSpacing.xxl),
          _RevenueStatisticsCard(summary: value),
          const SizedBox(height: AppSpacing.xxl),
          _QuickActions(),
          const SizedBox(height: AppSpacing.xxl),
          _RecentBookingsSection(),
        ],
      );
    },
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final saapaan = namaDepan(user?.nama);

    return Row(
      children: [
        if (user?.foto != null && user!.foto!.isNotEmpty)
          ClipOval(
            child: Image.network(
              user!.foto!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _AvatarFallback(),
            ),
          )
        else
          const _AvatarFallback(),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (saapaan != null)
                Text(
                  'Halo, $saapaan',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ringkasan Usaha',
                style: AppFonts.heading(
                  fontSize: 26,
                  weight: 700,
                  height: 1.1,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 24,
        color: AppColors.primaryInk,
      ),
    );
  }
}

/// Jumlah kolom kartu KPI sesuai lebar yang tersedia.
///
/// Di mobile tetap 2 kolom agar kartu kecil dan sejajar kiri-kanan,
/// bukan terlalu besar mengisi satu baris penuh.
int _kpiColumnCount(double width) {
  if (width >= 880) return 4;
  return 2;
}

/// Tinggi area grafik garis pada kartu statistik pendapatan.
const double _revenueChartHeight = 200;

/// Membuat satu bulan berjalan dengan nilai 0.
///
/// Dipakai saat belum ada data, supaya grafik tetap tampil sebagai
/// satu titik di garis dasar.
List<MonthlyRevenueModel> _bulanIniKosong() {
  final sekarang = DateTime.now();
  final nomorBulan = sekarang.month.toString().padLeft(2, '0');

  return [
    MonthlyRevenueModel(bulan: '${sekarang.year}-$nomorBulan', pendapatan: 0),
  ];
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Pendapatan Bersih',
        value: formatRupiah(summary.totalPendapatan),
        tone: AppColors.primaryDeep,
        surface: AppColors.lightOrange,
      ),
      _KpiData(
        icon: Icons.storefront_outlined,
        label: 'Total Tempat',
        value: '${summary.totalTempat}',
        tone: AppColors.primaryInk,
        surface: AppColors.lightOrange,
      ),
      _KpiData(
        icon: Icons.event_available_outlined,
        label: 'Penyewaan',
        value: '${summary.totalPemesanan}',
        tone: AppColors.primaryDeep,
        surface: AppColors.lightOrange,
      ),
      _KpiData(
        icon: Icons.check_circle_outline,
        label: 'Penyewaan Lunas',
        value: '${summary.pemesananLunas}',
        tone: AppColors.sage,
        surface: AppColors.sageTint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _kpiColumnCount(constraints.maxWidth);
        final gap = AppSpacing.xxl;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        // Wrap membuat tinggi kartu mengikuti isinya. GridView dengan
        // childAspectRatio memaksa tinggi tetap sehingga isi kartu overflow.
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.surface,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color surface;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 18, color: data.tone),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: AppFonts.heading(
                fontSize: 20,
                weight: 700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Statistik pendapatan: grafik garis dari semua aktivitas pemesanan lunas.
class _RevenueStatisticsCard extends StatelessWidget {
  const _RevenueStatisticsCard({required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    // Backend mengirim totalPendapatan = jumlah pendapatan_host, yaitu
    // pendapatan yang SUDAH dipotong komisi. Total pembayaran tenant adalah
    // pendapatan bersih ditambah komisi platform.
    final bersih = summary.totalPendapatan;
    final komisi = summary.totalKomisi;
    final total = bersih + komisi;
    final dataBulanan =
        summary.pendapatanBulanan ?? const <MonthlyRevenueModel>[];
    final bulanan = dataBulanan.isEmpty ? _bulanIniKosong() : dataBulanan;
    final terakhir = bulanan.last;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Statistik Pendapatan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                formatRupiah(terakhir.pendapatan),
                style: AppFonts.heading(
                  fontSize: 26,
                  weight: 700,
                  color: AppColors.charcoal,
                ),
              ),
              if (dataBulanan.length > 1) _TrendBadge(data: dataBulanan),
            ],
          ),
          Text(
            'Pendapatan ${terakhir.labelBulan}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _RevenueLineChart(data: bulanan),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(height: 1, color: AppColors.softBorder),
          const SizedBox(height: AppSpacing.lg),
          _RevenueInfoRow(label: 'Total Pembayaran Tenant', value: total),
          const SizedBox(height: AppSpacing.sm),
          _RevenueInfoRow(
            label: 'Komisi Platform',
            value: komisi,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

/// Badge naik/turun dibandingkan bulan sebelumnya.
class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.data});

  final List<MonthlyRevenueModel> data;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final sekarang = data[data.length - 1].pendapatan;
    final sebelumnya = data[data.length - 2].pendapatan;
    final selisih = sekarang - sebelumnya;

    if (selisih == 0) {
      return _badge(
        context,
        text: 'Sama dengan bulan lalu',
        color: AppColors.secondaryText,
        icon: Icons.remove_rounded,
      );
    }

    final naik = selisih > 0;
    final persen = sebelumnya > 0
        ? (selisih.abs() / sebelumnya * 100).round()
        : null;
    final text = persen == null
        ? (naik ? 'Naik bulan ini' : 'Turun bulan ini')
        : '${naik ? 'Naik' : 'Turun'} $persen% dari bulan lalu';

    return _badge(
      context,
      text: text,
      color: naik ? AppColors.success : AppColors.danger,
      icon: naik ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    );
  }

  Widget _badge(
    BuildContext context, {
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Grafik garis sederhana: pendapatan bersih tiap bulan.
///
/// Grafik digambar sendiri dengan CustomPainter supaya tidak perlu
/// menambah library chart baru.
class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.data});

  final List<MonthlyRevenueModel> data;

  @override
  Widget build(BuildContext context) {
    final gayaLabel =
        (Theme.of(context).textTheme.labelSmall ??
                const TextStyle(fontSize: 11))
            .copyWith(color: AppColors.secondaryText);

    return SizedBox(
      height: _revenueChartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _RevenueLinePainter(
          data: data,
          lineColor: AppColors.primaryDeep,
          gridColor: AppColors.softBorder,
          labelStyle: gayaLabel,
        ),
      ),
    );
  }
}

class _RevenueLinePainter extends CustomPainter {
  _RevenueLinePainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<MonthlyRevenueModel> data;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Ruang untuk label nominal (kiri) dan label bulan (bawah).
    const kiri = 44.0;
    const kanan = 28.0;
    const atas = 12.0;
    const bawah = 26.0;

    final lebar = size.width - kiri - kanan;
    final tinggi = size.height - atas - bawah;
    if (lebar <= 0 || tinggi <= 0) return;

    // 1. Cari nilai tertinggi. Kalau semua 0, pakai 1 supaya tidak dibagi 0.
    var tertinggi = 0.0;
    for (final item in data) {
      if (item.pendapatan > tertinggi) tertinggi = item.pendapatan;
    }
    final semuaNol = tertinggi == 0;
    final nilaiAtas = semuaNol ? 1.0 : tertinggi * 1.2;
    final yDasar = atas + tinggi;

    // 2. Hitung posisi titik: x rata, y sesuai pendapatan.
    final titik = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? kiri + lebar / 2
          : kiri + lebar * i / (data.length - 1);
      final y = atas + tinggi * (1 - data[i].pendapatan / nilaiAtas);
      titik.add(Offset(x, y));
    }

    // 3. Garis bantu: dasar selalu ada, garis atas hanya jika ada nilai.
    final catBantu = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(kiri, yDasar),
      Offset(kiri + lebar, yDasar),
      catBantu,
    );
    _tulisTeks(
      canvas,
      '0',
      Offset(kiri - 6, yDasar),
      rataKanan: true,
      tengahVertikal: true,
    );

    if (!semuaNol) {
      canvas.drawLine(Offset(kiri, atas), Offset(kiri + lebar, atas), catBantu);
      _tulisTeks(
        canvas,
        formatRupiahSingkat(tertinggi),
        Offset(kiri - 6, atas),
        rataKanan: true,
        tengahVertikal: true,
      );
    }

    // 4. Garis penghubung antar titik.
    if (titik.length > 1) {
      final garis = Path()..moveTo(titik.first.dx, titik.first.dy);
      for (var i = 1; i < titik.length; i++) {
        garis.lineTo(titik[i].dx, titik[i].dy);
      }
      canvas.drawPath(
        garis,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 5. Titik dan nama bulan.
    final catTitikPutih = Paint()..color = Colors.white;
    final catTitikGaris = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < titik.length; i++) {
      canvas.drawCircle(titik[i], 5, catTitikPutih);
      canvas.drawCircle(titik[i], 5, catTitikGaris);
      _tulisTeks(
        canvas,
        data[i].labelBulan,
        Offset(titik[i].dx, yDasar + 6),
        rataTengah: true,
      );
    }
  }

  /// Menulis teks di canvas dengan pengaturan posisi sederhana.
  void _tulisTeks(
    Canvas canvas,
    String teks,
    Offset posisi, {
    bool rataTengah = false,
    bool rataKanan = false,
    bool tengahVertikal = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: teks, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    var x = posisi.dx;
    var y = posisi.dy;

    if (rataTengah) x -= painter.width / 2;
    if (rataKanan) x -= painter.width;
    if (tengahVertikal) y -= painter.height / 2;

    painter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _RevenueLinePainter oldDelegate) => true;
}

/// Satu baris keterangan nominal pada kartu statistik.
class _RevenueInfoRow extends StatelessWidget {
  const _RevenueInfoRow({
    required this.label,
    required this.value,
    this.color = AppColors.charcoal,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          formatRupiah(value),
          style: Theme.of(context).textTheme.titleSmall!
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pindahTab(MainTab tab) {
      ref.read(mainNavIndexProvider.notifier).setTab(tab);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aksi Cepat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.storefront_outlined,
                  title: 'Kelola Tempat',
                  subtitle: 'Atur tempat & ketersediaan',
                  onTap: () => pindahTab(MainTab.kelolaTempat),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat Penyewaan',
                  subtitle: 'Pantau status setiap sewa',
                  onTap: () => pindahTab(MainTab.booking),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightOrange,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryDeep),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBookingsSection extends ConsumerWidget {
  const _RecentBookingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pemesanan Terbaru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(mainNavIndexProvider.notifier)
                    .setTab(MainTab.booking),
                child: Text(
                  'Lihat Semua',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          bookings.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ShimmerBox(
                width: double.infinity,
                height: 60,
                radius: AppRadius.lg,
              ),
            ),
            error: (error, _) => _InlineMessage(
              icon: Icons.wifi_off,
              message: 'Gagal memuat pemesanan.',
              onAction: () => ref.read(bookingsProvider.notifier).refresh(),
            ),
            data: (items) {
              final terbaru = items.take(3).toList();
              if (terbaru.isEmpty) {
                return const _InlineMessage(
                  icon: Icons.event_note,
                  message: 'Belum ada pemesanan masuk.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < terbaru.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.softBorder),
                    _RecentBookingTile(booking: terbaru[i]),
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

class _RecentBookingTile extends StatelessWidget {
  const _RecentBookingTile({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.namaTempat ?? 'Tempat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${booking.namaTenant ?? 'Penyewa'} - ${formatDateString(booking.tanggalMulai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(booking.totalHarga),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _StatusBadge(status: booking.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'LUNAS' => (AppColors.sageTint, AppColors.sage),
      'MENUNGGU_PEMBAYARAN' => (AppColors.lightOrange, AppColors.primaryInk),
      'DIBATALKAN' => (
        AppColors.danger.withValues(alpha: 0.1),
        AppColors.danger,
      ),
      _ => (AppColors.surfaceMuted, AppColors.secondaryText),
    };
    final label = switch (status) {
      'MENUNGGU_PEMBAYARAN' => 'Menunggu Bayar',
      'LUNAS' => 'Lunas',
      'DIBATALKAN' => 'Dibatalkan',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (onAction != null)
            TextButton(onPressed: onAction, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _kpiColumnCount(constraints.maxWidth);
        final gap = AppSpacing.xxl;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: cardWidth,
                child: const ShimmerBox(
                  width: double.infinity,
                  height: 128,
                  radius: AppRadius.lg,
                ),
              ),
          ],
        );
      },
    );
  }
}


