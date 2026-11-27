import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';
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
    final places = placesAsync.value;
    final kataKunci = ref.watch(
      tenantSearchProvider.select((state) => state.keyword),
    );

    // Daftar tempat sudah diurutkan dari yang paling baru dibuat,
    // jadi elemen pertama adalah tempat terbaru.
    final terbaru = places == null || places.isEmpty ? null : places.first;
    final lainnya = places == null || places.isEmpty
        ? const <PlaceModel>[]
        : places.skip(1).toList();
    final sorotan = lainnya.take(4).toList();
    final sisa = lainnya.length > 4 ? lainnya.sublist(4) : <PlaceModel>[];

    void bukaTempat() {
      ref.read(mainNavIndexProvider.notifier).setTab(MainTab.tempat);
    }

    void cari(String kataKunci) {
      ref.read(tenantSearchProvider.notifier).setKeyword(kataKunci);
      bukaTempat();
    }

    void kosongkan() {
      ref.read(tenantSearchProvider.notifier).setKeyword('');
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await ref.read(tenantPlacesProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppWidth.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Pencarian(onCari: cari, onKosongkan: kosongkan),
                  ),
                  const SizedBox(height: 24),
                  if (placesAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _PesanGagal(
                        onMuatUlang: () =>
                            ref.read(tenantPlacesProvider.notifier).refresh(),
                      ),
                    )
                  else if (places == null)
                    const PlaceGridSkeleton(count: 3)
                  else if (places.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: kataKunci.trim().isEmpty
                          ? const EmptyState(
                              icon: Icons.storefront_outlined,
                              title: 'Belum ada tempat tersedia',
                              message:
                                  'Saat ini belum ada ruang usaha yang dibuka '
                                  'untuk disewa. Coba periksa lagi nanti.',
                            )
                          : EmptyState(
                              icon: Icons.search_off,
                              title: 'Tempat tidak ditemukan',
                              message:
                                  'Tidak ada tempat yang cocok dengan '
                                  '"${kataKunci.trim()}". Hapus kata kunci '
                                  'untuk melihat semua tempat.',
                              actionLabel: 'Hapus pencarian',
                              onAction: kosongkan,
                            ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _DaftarTempat(
                        terbaru: terbaru!,
                        sorotan: sorotan,
                        sisa: sisa,
                        onLihatSemua: bukaTempat,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaftarTempat extends StatelessWidget {
  const _DaftarTempat({
    required this.terbaru,
    required this.sorotan,
    required this.sisa,
    required this.onLihatSemua,
  });

  final PlaceModel terbaru;
  final List<PlaceModel> sorotan;
  final List<PlaceModel> sisa;
  final VoidCallback onLihatSemua;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final duaKolom = MediaQuery.sizeOf(context).width >= AppWidth.sidebar;

        if (!duaKolom) {
          final lainnya = [...sorotan, ...sisa];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpothSectionHeader(title: 'Tempat terbaru'),
              const SizedBox(height: 12),
              _TempatTerbaru(place: terbaru),
              const SizedBox(height: 10),
              _AksiTerbaru(onLihatSemua: onLihatSemua),
              if (lainnya.isNotEmpty) ...[
                const SizedBox(height: 28),
                const SpothSectionHeader(title: 'Tempat untukmu'),
                const SizedBox(height: 12),
                PlaceGrid(places: lainnya),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SpothSectionHeader(title: 'Tempat terbaru'),
            const SizedBox(height: 12),
            _Sorotan(terbaru: terbaru, sorotan: sorotan),
            const SizedBox(height: 10),
            _AksiTerbaru(onLihatSemua: onLihatSemua),
            if (sisa.isNotEmpty) ...[
              const SizedBox(height: 28),
              const SpothSectionHeader(title: 'Tempat untukmu'),
              const SizedBox(height: 12),
              PlaceGrid(places: sisa),
            ],
          ],
        );
      },
    );
  }
}

class _Sorotan extends StatelessWidget {
  const _Sorotan({required this.terbaru, required this.sorotan});

  final PlaceModel terbaru;
  final List<PlaceModel> sorotan;

  @override
  Widget build(BuildContext context) {
    if (sorotan.isEmpty) {
      return _TempatTerbaru(place: terbaru);
    }

    const jarak = 12.0;
    const tinggiBaris = 88.0;
    final tinggiDaftar =
        sorotan.length * tinggiBaris + (sorotan.length - 1) * jarak;
    final tinggi = tinggiDaftar.clamp(320.0, 560.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const celah = 16.0;
        final lebarKanan = constraints.maxWidth * 0.4;
        final lebarKiri = constraints.maxWidth - celah - lebarKanan;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: lebarKiri,
              child: _TempatTerbaru(place: terbaru, tinggi: tinggi),
            ),
            const SizedBox(width: celah),
            SizedBox(
              width: lebarKanan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sorotan.length; i++) ...[
                    SizedBox(
                      height: tinggiBaris,
                      child: _BarisSorotan(place: sorotan[i]),
                    ),
                    if (i < sorotan.length - 1)
                      const SizedBox(height: jarak),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarisSorotan extends StatelessWidget {
  const _BarisSorotan({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;
    final harga = place.paketTermurah;

    return Material(
      key: const ValueKey('baris-sorotan'),
      color: AppColors.canvas,
      child: InkWell(
        onTap: () => context.push('/place-detail?id=${place.id}'),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 72,
                height: 72,
                child: foto != null
                    ? Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const PlacePhotoPlaceholder(),
                      )
                    : const PlacePhotoPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    place.namaTempat,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (harga != null)
                    Text(
                      '${formatRupiah(harga.harga)} / ${harga.satuan}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempatTerbaru extends StatelessWidget {
  const _TempatTerbaru({required this.place, this.tinggi});

  final PlaceModel place;
  final double? tinggi;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('tempat-terbaru'),
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.charcoal,
        child: InkWell(
          onTap: () => context.push('/place-detail?id=${place.id}'),
          child: tinggi == null
              ? AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _IsiTerbaru(place: place),
                )
              : SizedBox(height: tinggi, child: _IsiTerbaru(place: place)),
        ),
      ),
    );
  }
}

class _IsiTerbaru extends StatelessWidget {
  const _IsiTerbaru({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        foto != null
            ? Image.network(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const PlacePhotoPlaceholder(),
              )
            : const PlacePhotoPlaceholder(),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                place.namaTempat,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.white,
                  shadows: [
                    Shadow(
                      color: Color(0xB3000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _HargaDiAtasFoto(paket: place.paket),
            ],
          ),
        ),
      ],
    );
  }
}

class _HargaDiAtasFoto extends StatelessWidget {
  const _HargaDiAtasFoto({required this.paket});

  final List<PaketSewa> paket;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final item in paket)
          Text(
            '${formatRupiah(item.harga)} / ${item.satuan}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              shadows: [
                Shadow(
                  color: Color(0xB3000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AksiTerbaru extends StatelessWidget {
  const _AksiTerbaru({required this.onLihatSemua});

  final VoidCallback onLihatSemua;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _TautanAksi(label: 'Lihat semua', onTap: onLihatSemua),
    );
  }
}

class _Pencarian extends StatefulWidget {
  const _Pencarian({required this.onCari, required this.onKosongkan});

  final ValueChanged<String> onCari;
  final VoidCallback onKosongkan;

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

  void _ubah(String nilai) {
    // Menghapus seluruh teks harus mengembalikan semua tempat, bukan
    // meninggalkan filter kata kunci lama.
    if (nilai.trim().isEmpty) {
      widget.onKosongkan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _kirim,
        onChanged: _ubah,
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
