import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/booking_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

String _lokasiLengkap(PlaceModel place) {
  final alamat = place.alamat.trim();
  final kecamatan = place.kecamatan.trim();

  if (kecamatan.isEmpty) return alamat;
  if (alamat.toLowerCase().contains(kecamatan.toLowerCase())) return alamat;

  return '$alamat, $kecamatan';
}

bool _punyaPesananAktif(
  String placeId,
  AsyncValue<List<BookingModel>> bookingsAsync,
) {
  final daftar = bookingsAsync.value;
  if (daftar == null) {
    return false;
  }

  final hariIni = formatTanggalApi(DateTime.now());

  return daftar.any((booking) {
    final belumSelesai = booking.tanggalSelesai.compareTo(hariIni) >= 0;
    final masihAktif =
        booking.status == 'MENUNGGU_PEMBAYARAN' || booking.status == 'LUNAS';

    return booking.placeId == placeId && belumSelesai && masihAktif;
  });
}

PaketSewa? _paketTerpilih(PlaceModel place, String? tipe) {
  final daftar = place.paket;
  if (daftar.isEmpty) {
    return null;
  }

  for (final item in daftar) {
    if (item.tipe == tipe) {
      return item;
    }
  }

  return daftar.first;
}

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  PlaceModel? _place;
  bool _loading = true;
  String? _error;
  int _fotoIndex = 0;
  String? _paketAktif;

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
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: widget.placeId, token: token);

      if (!mounted) return;
      setState(() {
        _place = place;
        _fotoIndex = 0;
        _paketAktif = place.paketTermurah?.tipe;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat detail tempat');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: widget.placeId, token: token);

      if (!mounted) return;
      setState(() {
        _place = place;
        _fotoIndex = 0;
        if (_paketTerpilih(place, _paketAktif) == null) {
          _paketAktif = place.paketTermurah?.tipe;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui detail tempat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final place = _place;
    final isOwner =
        user?.role == UserModel.roleHost &&
        place != null &&
        user!.id == place.hostId;
    final isTenant = user?.role == UserModel.roleTenant;
    final sudahMenyewa =
        place != null && _punyaPesananAktif(place.id, ref.watch(bookingsProvider));

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(title: Text('Detail Tempat')),
      body: _loading
          ? const SingleChildScrollView(child: DetailSkeleton())
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
          : place == null
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.storefront,
                  title: 'Tempat tidak ditemukan',
                  message: 'Data tempat tidak tersedia di server.',
                ),
              ),
            )
          : _DetailScrollView(
              place: place,
              fotoIndex: _fotoIndex,
              onFotoChanged: (index) => setState(() => _fotoIndex = index),
              onRefresh: _refresh,
              paketAktif: _paketAktif,
              onPaketChanged: (tipe) => setState(() => _paketAktif = tipe),
              isOwner: isOwner,
              isTenant: isTenant,
              sudahMenyewa: sudahMenyewa,
            ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.tempat, child: page);
  }
}

class _DetailScrollView extends StatelessWidget {
  const _DetailScrollView({
    required this.place,
    required this.fotoIndex,
    required this.onFotoChanged,
    required this.onRefresh,
    required this.paketAktif,
    required this.onPaketChanged,
    required this.isOwner,
    required this.isTenant,
    required this.sudahMenyewa,
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;
  final Future<void> Function() onRefresh;
  final String? paketAktif;
  final ValueChanged<String> onPaketChanged;
  final bool isOwner;
  final bool isTenant;
  final bool sudahMenyewa;

  @override
  Widget build(BuildContext context) {
    final duaKolom = MediaQuery.sizeOf(context).width >= AppWidth.sidebar;

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ruang = constraints.maxWidth;
            return duaKolom ? _detailLebar(ruang) : _detailSempit(ruang);
          },
        ),
      ),
    );
  }

  Widget _detailLebar(double ruang) {
    const paddingSamping = 32.0;
    const jarakKolom = 24.0;
    final lebarIsi = ruang - paddingSamping;
    final lebarKiri = (lebarIsi - jarakKolom) * 0.46;
    final lebarKanan = lebarIsi - jarakKolom - lebarKiri;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: lebarKiri,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPhoto(
                  place: place,
                  fotoIndex: fotoIndex,
                  lebar: lebarKiri,
                  tinggi: (lebarKiri * 0.78).clamp(230.0, 430.0),
                  onFotoChanged: onFotoChanged,
                ),
                if (place.foto.length > 1) ...[
                  const SizedBox(height: 10),
                  _HeroThumbs(
                    place: place,
                    fotoIndex: fotoIndex,
                    onFotoChanged: onFotoChanged,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: jarakKolom),
          SizedBox(width: lebarKanan, child: _rincian()),
        ],
      ),
    );
  }

  Widget _detailSempit(double ruang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPhoto(
          key: const ValueKey('foto-utama-ponsel'),
          place: place,
          fotoIndex: fotoIndex,
          lebar: ruang,
          tinggi: (ruang * 0.78).clamp(240.0, 380.0),
          radius: 0,
          onFotoChanged: onFotoChanged,
        ),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (place.foto.length > 1) ...[
                  _HeroThumbs(
                    place: place,
                    fotoIndex: fotoIndex,
                    onFotoChanged: onFotoChanged,
                  ),
                  const SizedBox(height: 18),
                ],
                _rincian(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rincian() {
    final deskripsi = place.deskripsi.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KepalaTempat(
          place: place,
          paketAktif: paketAktif,
          onPaketChanged: onPaketChanged,
        ),
        const SizedBox(height: 20),
        if (deskripsi.isNotEmpty) ...[
          _DetailSectionCard(
            title: 'Deskripsi',
            child: Text(
              deskripsi,
              style: const TextStyle(
                fontSize: 14,
                height: 1.65,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _AksiSewa(
          place: place,
          isOwner: isOwner,
          isTenant: isTenant,
          sudahMenyewa: sudahMenyewa,
        ),
        const SizedBox(height: 20),
        _DetailSectionCard(
          title: 'Jadwal Sudah Dipesan',
          child: _JadwalDipesan(place: place),
        ),
        const SizedBox(height: 16),
        _KeteranganUpdate(place: place),
      ],
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    super.key,
    required this.place,
    required this.fotoIndex,
    required this.lebar,
    required this.tinggi,
    required this.onFotoChanged,
    this.radius = 18,
  });

  final PlaceModel place;
  final int fotoIndex;
  final double lebar;
  final double tinggi;
  final ValueChanged<int> onFotoChanged;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final index = fotos.isEmpty ? 0 : fotoIndex.clamp(0, fotos.length - 1);
    final aktif = fotos.isNotEmpty ? fotos[index] : null;
    final adaNavigasi = fotos.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: tinggi,
        width: lebar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            aktif != null
                ? Image.network(
                    aktif,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _HeroPlaceholder(),
                  )
                : const _HeroPlaceholder(),
            if (adaNavigasi)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final keKanan = details.localPosition.dx > lebar / 2;
                  final baru = (index + (keKanan ? 1 : -1)) % fotos.length;
                  onFotoChanged(baru < 0 ? fotos.length - 1 : baru);
                },
              ),
            if (adaNavigasi)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _GalleryCue(icon: Icons.chevron_left),
                      _GalleryCue(icon: Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            if (aktif != null)
              Positioned(
                top: 12,
                right: 12,
                child: _GalleryButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Perbesar foto',
                  onPressed: () => _bukaFoto(context, fotos, index),
                ),
              ),
            if (adaNavigasi)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${index + 1} / ${fotos.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaFoto(BuildContext context, List<String> fotos, int mulai) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.9),
      builder: (_) => _PhotoViewer(fotos: fotos, initialIndex: mulai),
    );
  }
}

class _HeroThumbs extends StatelessWidget {
  const _HeroThumbs({
    required this.place,
    required this.fotoIndex,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final index = fotos.isEmpty ? 0 : fotoIndex.clamp(0, fotos.length - 1);

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final dipilih = i == index;

          return GestureDetector(
            key: ValueKey('galeri-thumb-$i'),
            onTap: () => onFotoChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 78,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dipilih
                      ? AppColors.primaryOrange
                      : AppColors.softBorder,
                  width: dipilih ? 2 : 1,
                ),
              ),
              child: Image.network(
                fotos[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _HeroPlaceholder(iconSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.charcoal.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.fotos, required this.initialIndex});

  final List<String> fotos;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initialIndex.clamp(0, widget.fotos.length - 1);

  void _geser(int arah) {
    setState(() {
      _index = (_index + arah) % widget.fotos.length;
      if (_index < 0) _index = widget.fotos.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaNavigasi = widget.fotos.length > 1;

    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.charcoal,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  widget.fotos[_index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Center(child: _HeroPlaceholder()),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _ViewerButton(
                icon: Icons.close,
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (adaNavigasi) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Foto sebelumnya',
                    onPressed: () => _geser(-1),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Foto berikutnya',
                    onPressed: () => _geser(1),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Text(
                    '${_index + 1} / ${widget.fotos.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _GalleryCue extends StatelessWidget {
  const _GalleryCue({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.charcoal.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.white),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({this.iconSize = 64});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(
          Icons.storefront,
          size: iconSize,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _KepalaTempat extends StatelessWidget {
  const _KepalaTempat({
    required this.place,
    required this.paketAktif,
    required this.onPaketChanged,
  });

  final PlaceModel place;
  final String? paketAktif;
  final ValueChanged<String> onPaketChanged;

  @override
  Widget build(BuildContext context) {
    final paket = _paketTerpilih(place, paketAktif);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.namaTempat,
          style: AppFonts.heading(
            fontSize: 24,
            weight: 600,
            height: 1.25,
            letterSpacing: -0.4,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _lokasiLengkap(place),
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BarisPemilik(place: place),
        if (paket != null) ...[
          const SizedBox(height: 14),
          _PemilihPaketHarga(
            daftar: place.paket,
            aktif: paket.tipe,
            onPilih: onPaketChanged,
            harga: paket.harga,
            satuan: labelSatuan(paket.tipe),
          ),
        ],
      ],
    );
  }
}

class _PemilihPaketHarga extends StatelessWidget {
  const _PemilihPaketHarga({
    required this.daftar,
    required this.aktif,
    required this.onPilih,
    required this.harga,
    required this.satuan,
  });

  final List<PaketSewa> daftar;
  final String aktif;
  final ValueChanged<String> onPilih;
  final double harga;
  final String satuan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < daftar.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _TombolPaket(
                label: daftar[i].label,
                aktif: daftar[i].tipe == aktif,
                onPressed: () => onPilih(daftar[i].tipe),
              ),
            ],
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${formatRupiah(harga)} /$satuan',
              maxLines: 1,
              style: AppFonts.heading(
                fontSize: 18,
                weight: 700,
                letterSpacing: -0.4,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TombolPaket extends StatelessWidget {
  const _TombolPaket({
    required this.label,
    required this.aktif,
    required this.onPressed,
  });

  final String label;
  final bool aktif;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: aktif ? AppColors.primaryDeep : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: aktif ? AppColors.white : AppColors.charcoal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JadwalDipesan extends StatelessWidget {
  const _JadwalDipesan({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    if (place.jadwalTerpakai.isEmpty) {
      return const Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 18,
            color: AppColors.primaryOrange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum ada jadwal yang terisi. Semua tanggal masih tersedia.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < place.jadwalTerpakai.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _BookedScheduleRow(jadwal: place.jadwalTerpakai[i]),
        ],
      ],
    );
  }
}

class _KeteranganUpdate extends StatelessWidget {
  const _KeteranganUpdate({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final updatedAt = place.updatedAt;
    if (updatedAt == null) {
      return const SizedBox.shrink();
    }

    return Text(
      'Terakhir diperbarui ${formatTanggal(updatedAt)}',
      style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
    );
  }
}

class _BarisPemilik extends StatelessWidget {
  const _BarisPemilik({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final fotoHost = place.fotoHost?.trim() ?? '';

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 32,
            height: 32,
            child: fotoHost.isNotEmpty
                ? Image.network(
                    fotoHost,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _FotoPemilikKosong(),
                  )
                : const _FotoPemilikKosong(),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Pemilik tempat',
          style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _FotoPemilikKosong extends StatelessWidget {
  const _FotoPemilikKosong();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(Icons.person_outline, size: 20, color: AppColors.primaryDeep),
      ),
    );
  }
}

class _BookedScheduleRow extends StatelessWidget {
  const _BookedScheduleRow({required this.jadwal});

  final BookedRange jadwal;

  @override
  Widget build(BuildContext context) {
    final status = jadwal.status?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy,
            size: 18,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatDateString(jadwal.tanggalMulai)} - '
              '${formatDateString(jadwal.tanggalSelesai)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.charcoal,
              ),
            ),
          ),
          if (status != null && status.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AksiSewa extends StatelessWidget {
  const _AksiSewa({
    required this.place,
    required this.isOwner,
    required this.isTenant,
    required this.sudahMenyewa,
  });

  final PlaceModel place;
  final bool isOwner;
  final bool isTenant;
  final bool sudahMenyewa;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return const SizedBox.shrink();
    }

    if (!isTenant) {
      return const _CatatanAksi(
        icon: Icons.info_outline,
        teks: 'Masuk sebagai penyewa untuk menyewa tempat ini.',
      );
    }

    if (sudahMenyewa) {
      return const _CatatanAksi(
        icon: Icons.check_circle_outline,
        teks: 'Anda sudah menyewa tempat ini. Lihat detailnya di Riwayat.',
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        key: const ValueKey('tombol-sewa'),
        onPressed: () => context.push('/booking-form?id=${place.id}'),
        icon: const Icon(Icons.event_available, size: 18),
        label: const Text('Sewa Tempat Ini'),
      ),
    );
  }
}

class _CatatanAksi extends StatelessWidget {
  const _CatatanAksi({required this.icon, required this.teks});

  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teks,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
