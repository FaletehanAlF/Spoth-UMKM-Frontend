import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/category_style.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/place_grid.dart';
import '../../widgets/place_grid_card.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_page.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(tenantPlacesProvider);
    final bookingAktif = _penyewaanAktif(ref.watch(bookingsProvider));

    final places = placesAsync.value;
    final rekomendasi = places == null || places.isEmpty
        ? <PlaceModel>[]
        : places.take(3).toList();
    final sisa = places == null ? const <PlaceModel>[] : places.skip(3).toList();

    void bukaTempat() {
      ref.read(mainNavIndexProvider.notifier).setTab(MainTab.tempat);
    }

    void cari(String kataKunci) {
      ref.read(tenantSearchProvider.notifier).setKeyword(kataKunci);
      bukaTempat();
    }

    void pilihKategori(String kategori) {
      ref.read(tenantSearchProvider.notifier).setKategori(kategori);
      bukaTempat();
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await ref.read(tenantPlacesProvider.notifier).refresh();
          await ref.read(bookingsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppWidth.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Pencarian(onCari: cari),
                  const SizedBox(height: 24),
                  if (placesAsync.hasError)
                    _PesanGagal(
                      onMuatUlang: () =>
                          ref.read(tenantPlacesProvider.notifier).refresh(),
                    )
                  else if (places == null)
                    const PlaceGridSkeleton(count: 3)
                  else if (places.isEmpty)
                    const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Belum ada tempat tersedia',
                      message:
                          'Saat ini belum ada ruang usaha yang dibuka untuk '
                          'disewa. Coba periksa lagi nanti.',
                    )
                  else ...[
                    SpothSectionHeader(
                      title: 'Tempat terbaru',
                      subtitle: 'Baru dibuka oleh pemilik tempat',
                      action: _TautanAksi(
                        label: 'Lihat semua',
                        onTap: bukaTempat,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CarouselTerbaru(places: rekomendasi),
                  ],
                  const SizedBox(height: 24),
                  _KategoriBaris(onPilih: pilihKategori),
                  if (bookingAktif != null) ...[
                    const SizedBox(height: 28),
                    const SpothSectionHeader(
                      title: 'Penyewaan berjalan',
                      subtitle: 'Pesananmu yang sedang aktif',
                    ),
                    const SizedBox(height: 12),
                    _KartuPenyewaan(booking: bookingAktif),
                  ],
                  if (sisa.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    SpothSectionHeader(
                      title: 'Tempat untukmu',
                      subtitle: 'Pilihan ruang usaha lainnya',
                      action: _TautanAksi(
                        label: 'Lihat semua',
                        onTap: bukaTempat,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PlaceGrid(places: sisa),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BookingModel? _penyewaanAktif(AsyncValue<List<BookingModel>> bookingsAsync) {
  final daftar = bookingsAsync.value;
  if (daftar == null || daftar.isEmpty) {
    return null;
  }

  final hariIni = formatTanggalApi(DateTime.now());

  final aktif = daftar.where((booking) {
    final belumSelesai = booking.tanggalSelesai.compareTo(hariIni) >= 0;
    return belumSelesai &&
        (booking.status == 'MENUNGGU_PEMBAYARAN' || booking.status == 'LUNAS');
  }).toList();

  if (aktif.isEmpty) {
    return null;
  }

  aktif.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

  return aktif.first;
}

class _Pencarian extends StatefulWidget {
  const _Pencarian({required this.onCari});

  final ValueChanged<String> onCari;

  @override
  State<_Pencarian> createState() => _PencarianState();
}

class _PencarianState extends State<_Pencarian> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _kirim(String nilai) {
    final kataKunci = nilai.trim();
    if (kataKunci.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onCari(kataKunci);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _kirim,
        style: const TextStyle(fontSize: 14, color: AppColors.darkText),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceMuted,
          hintText: 'Cari tempat atau kecamatan',
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.secondaryText,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.softBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(
              color: AppColors.primaryDeep,
              width: 1.6,
            ),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Cari',
              onPressed: () => _kirim(_controller.text),
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselTerbaru extends StatelessWidget {
  const _CarouselTerbaru({required this.places});

  final List<PlaceModel> places;

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.sizeOf(context).width;
    final lebarKartu = lebarLayar >= 900
        ? 320.0
        : lebarLayar >= 600
        ? 288.0
        : 250.0;

    return SizedBox(
      key: const ValueKey('carousel-terbaru'),
      height: 312,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: lebarKartu,
            child: PlaceGridCard(place: places[index]),
          ),
        ),
      ),
    );
  }
}

class _PesanGagal extends StatelessWidget {
  const _PesanGagal({required this.onMuatUlang});

  final VoidCallback onMuatUlang;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Gagal memuat tempat',
      message: 'Koneksi ke server terputus. Periksa internetmu lalu coba lagi.',
      actionLabel: 'Coba lagi',
      onAction: onMuatUlang,
    );
  }
}

class _KategoriBaris extends StatelessWidget {
  const _KategoriBaris({required this.onPilih});

  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    const kategori = ['LAPAK_USAHA', 'TERAS_KOMERSIAL', 'BOOTH_EVENT'];

    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: [
        for (final nama in kategori)
          _KategoriTombol(
            ikon: categoryIcon(nama),
            label: categoryLabel(nama),
            onTap: () => onPilih(nama),
          ),
      ],
    );
  }
}

class _KategoriTombol extends StatelessWidget {
  const _KategoriTombol({
    required this.ikon,
    required this.label,
    required this.onTap,
  });

  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.lightOrange,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(ikon, size: 22, color: AppColors.primaryInk),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _TautanAksi extends StatelessWidget {
  const _TautanAksi({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryInk,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 44),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _KartuPenyewaan extends StatelessWidget {
  const _KartuPenyewaan({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final perluBayar = booking.status == 'MENUNGGU_PEMBAYARAN';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.namaTempat ?? 'Tempat usaha',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _LencanaStatus(perluBayar: perluBayar),
            ],
          ),
          const SizedBox(height: 12),
          _BarisInfo(
            ikon: Icons.calendar_month_outlined,
            teks:
                '${formatDateString(booking.tanggalMulai)} – '
                '${formatDateString(booking.tanggalSelesai)}',
          ),
          const SizedBox(height: 6),
          _BarisInfo(
            ikon: Icons.payments_outlined,
            teks: perluBayar
                ? 'Perlu dibayar ${formatRupiah(booking.totalHarga)}'
                : 'Sudah dibayar ${formatRupiah(booking.totalHarga)}',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () async {
                if (perluBayar) {
                  await context.push('/payment?id=${booking.id}');
                } else {
                  await context.push('/riwayat');
                }
                if (context.mounted) {
                  context.go('/home');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                perluBayar ? 'Lanjutkan pembayaran' : 'Lihat E-Pass',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LencanaStatus extends StatelessWidget {
  const _LencanaStatus({required this.perluBayar});

  final bool perluBayar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: perluBayar ? AppColors.lightOrange : AppColors.sageTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        perluBayar ? 'Belum dibayar' : 'Aktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: perluBayar ? AppColors.primaryInk : AppColors.success,
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teks,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
