import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  PlaceModel? _place;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  int _fotoIndex = 0;

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
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui detail tempat.')),
      );
    }
  }

  Future<void> _toggleStatus() async {
    final place = _place;
    if (place == null || _acting) return;

    setState(() => _acting = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      await ref
          .read(placeServiceProvider)
          .updatePlace(
            token: token,
            id: place.id,
            payload: {'status': place.isAktif ? 'NONAKTIF' : 'AKTIF'},
          );

      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah status tempat.')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete() async {
    final place = _place;
    if (place == null || _acting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tempat ini?'),
        content: const Text('Tempat yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      await ref
          .read(placeServiceProvider)
          .deletePlace(token: token, id: place.id);
      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tempat berhasil dihapus')));
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus tempat.')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _edit() async {
    final place = _place;
    if (place == null || _acting) return;

    final saved = await context.push('/place-form?id=${place.id}');
    if (saved == true && mounted) {
      await _load();
      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();
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

    final page = Scaffold(
      backgroundColor: AppColors.white,
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
          : Column(
              children: [
                Expanded(
                  child: _DetailScrollView(
                    place: place,
                    fotoIndex: _fotoIndex,
                    onFotoChanged: (index) =>
                        setState(() => _fotoIndex = index),
                    onRefresh: _refresh,
                  ),
                ),
                _ActionBar(
                  place: place,
                  isOwner: isOwner,
                  isTenant: isTenant,
                  acting: _acting,
                  onToggleStatus: _toggleStatus,
                  onDelete: _delete,
                  onEdit: _edit,
                ),
              ],
            ),
    );

    return SpothSidebarScaffold(activeNavIndex: 1, child: page);
  }
}

class _DetailScrollView extends StatelessWidget {
  const _DetailScrollView({
    required this.place,
    required this.fotoIndex,
    required this.onFotoChanged,
    required this.onRefresh,
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ruang = constraints.maxWidth;
          const jarakKolom = 32.0;
          final duaKolom = ruang >= 840;
          final lebarKiri = duaKolom ? (ruang - jarakKolom) * 0.46 : ruang;
          final lebarKanan = duaKolom ? ruang - jarakKolom - lebarKiri : ruang;

          final gallery = _HeroGallery(
            place: place,
            fotoIndex: fotoIndex,
            lebar: lebarKiri,
            tinggi: duaKolom
                ? (lebarKiri * 0.78).clamp(230.0, 430.0)
                : (ruang * 0.56).clamp(200.0, 320.0),
            onFotoChanged: onFotoChanged,
          );

          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: duaKolom
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        gallery,
                        const SizedBox(width: jarakKolom),
                        SizedBox(
                          width: lebarKanan,
                          child: _DetailSheet(place: place),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        gallery,
                        const SizedBox(height: 16),
                        _DetailSheet(place: place),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroGallery extends StatelessWidget {
  const _HeroGallery({
    required this.place,
    required this.fotoIndex,
    required this.lebar,
    required this.tinggi,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final double lebar;
  final double tinggi;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final index = fotos.isEmpty ? 0 : fotoIndex.clamp(0, fotos.length - 1);
    final aktif = fotos.isNotEmpty ? fotos[index] : null;
    final adaNavigasi = fotos.length > 1;

    return SizedBox(
      width: lebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                        final baru =
                            (index + (keKanan ? 1 : -1)) % fotos.length;
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
                          color: Colors.black.withValues(alpha: 0.55),
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
          ),
          if (adaNavigasi) ...[
            const SizedBox(height: 10),
            SizedBox(
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
                        errorBuilder: (_, _, _) =>
                            const _HeroPlaceholder(iconSize: 22),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _bukaFoto(BuildContext context, List<String> fotos, int mulai) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _PhotoViewer(fotos: fotos, initialIndex: mulai),
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
        color: Colors.black.withValues(alpha: 0.45),
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
        color: Colors.black,
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
          color: Colors.black.withValues(alpha: 0.45),
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

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final namaHost = place.namaHost?.trim();
    final adaDeskripsi =
        place.deskripsi != null && place.deskripsi!.trim().isNotEmpty;
    final adaFasilitas = place.fasilitasList.isNotEmpty;
    final adaAturan = place.aturan != null && place.aturan!.trim().isNotEmpty;

    final ringkasan = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoBadge(label: place.kategoriLabel),
            _StatusBadge(isAktif: place.isAktif),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          place.namaTempat,
          style: AppFonts.heading(
            fontSize: 27,
            weight: 600,
            height: 1.2,
            letterSpacing: -0.4,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 10),
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
                '${place.alamat}, ${place.kota}',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _PriceBlock(place: place),
        const SizedBox(height: 22),
        _SpecRow(place: place),
        if (namaHost != null && namaHost.isNotEmpty) ...[
          const SizedBox(height: 22),
          _HostRow(namaHost: namaHost),
        ],
      ],
    );

    final rincian = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (adaDeskripsi) ...[
          const _SectionTitle('Deskripsi'),
          const SizedBox(height: 10),
          Text(
            place.deskripsi!.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.secondaryText,
            ),
          ),
        ],
        if (adaFasilitas) ...[
          const SizedBox(height: 26),
          const _SectionTitle('Fasilitas'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fasilitas in place.fasilitasList)
                _FasilitasChip(label: fasilitas),
            ],
          ),
        ],
        if (adaAturan) ...[
          const SizedBox(height: 26),
          const _SectionTitle('Aturan'),
          const SizedBox(height: 12),
          _CatatanBox(isi: place.aturan!.trim()),
        ],
        const SizedBox(height: 26),
        _BookedSchedules(place: place),
        if (place.updatedAt != null) ...[
          const SizedBox(height: 20),
          Text(
            'Terakhir diperbarui ${formatTanggal(place.updatedAt)}',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ringkasan,
          const SizedBox(height: 24),
          Container(height: 1, color: AppColors.softBorder),
          const SizedBox(height: 24),
          rincian,
        ],
      ),
    );
  }
}

class _CatatanBox extends StatelessWidget {
  const _CatatanBox({required this.isi});

  final String isi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 17,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isi,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isAktif});

  final bool isAktif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAktif ? AppColors.primaryOrange : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isAktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isAktif ? AppColors.white : AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final diskon = formatDiskonPersen(place.hargaNormal, place.hargaPromo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(place.hargaEfektif),
                  maxLines: 1,
                  style: AppFonts.heading(
                    fontSize: 26,
                    weight: 700,
                    letterSpacing: -0.6,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/${place.durasiLabel.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
        if (diskon != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatRupiah(place.hargaNormal),
                style: const TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  diskon,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _SpecItem(
              icon: Icons.event_repeat,
              value: place.durasiLabel,
              label: 'Durasi',
            ),
          ),
          const _SpecDivider(),
          Expanded(
            child: _SpecItem(
              icon: Icons.photo_library_outlined,
              value: '${place.foto.length}',
              label: 'Foto',
            ),
          ),
          const _SpecDivider(),
          Expanded(
            child: _SpecItem(
              icon: Icons.event_busy_outlined,
              value: '${place.jadwalTerpakai.length}',
              label: 'Jadwal Terisi',
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.softBorder);
  }
}

class _HostRow extends StatelessWidget {
  const _HostRow({required this.namaHost});

  final String namaHost;

  @override
  Widget build(BuildContext context) {
    final inisial = namaHost.characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
          ),
          child: Text(
            inisial,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                namaHost,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Pemilik tempat',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FasilitasChip extends StatelessWidget {
  const _FasilitasChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 15,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookedSchedules extends StatelessWidget {
  const _BookedSchedules({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Jadwal Sudah Dipesan'),
        const SizedBox(height: 10),
        if (place.jadwalTerpakai.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: const Row(
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
            ),
          )
        else
          for (var i = 0; i < place.jadwalTerpakai.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _BookedScheduleRow(jadwal: place.jadwalTerpakai[i]),
          ],
      ],
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
              '${formatDateString(jadwal.tanggalMulai)} – '
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.place,
    required this.isOwner,
    required this.isTenant,
    required this.acting,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
  });

  final PlaceModel place;
  final bool isOwner;
  final bool isTenant;
  final bool acting;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget content;
    if (isOwner) {
      final tombol = ElevatedButton.icon(
        onPressed: acting ? null : () => _showKelolaSheet(context),
        icon: const Icon(Icons.tune, size: 18),
        label: Text(acting ? 'Memproses...' : 'Kelola Tempat'),
      );

      content = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 520) {
            return Row(
              children: [
                Expanded(child: _BarStatus(place: place)),
                const SizedBox(width: 24),
                SizedBox(width: 260, height: 48, child: tombol),
              ],
            );
          }

          return SizedBox(width: double.infinity, height: 48, child: tombol);
        },
      );
    } else if (isTenant) {
      if (place.isAktif) {
        final tombol = ElevatedButton.icon(
          onPressed: () => context.push('/booking-form?id=${place.id}'),
          icon: const Icon(Icons.event_available, size: 18),
          label: const Text('Sewa Tempat Ini'),
        );

        content = LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 520) {
              return Row(
                children: [
                  Expanded(child: _BarHarga(place: place)),
                  const SizedBox(width: 24),
                  SizedBox(width: 240, height: 48, child: tombol),
                ],
              );
            }

            return SizedBox(width: double.infinity, height: 48, child: tombol);
          },
        );
      } else {
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Tempat Sedang Nonaktif',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        );
      }
    } else {
      content = Row(
        children: const [
          Icon(Icons.info_outline, size: 18, color: AppColors.secondaryText),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tempat ini dikelola oleh akun lain.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: content,
        ),
      ),
    );
  }

  Future<void> _showKelolaSheet(BuildContext context) async {
    final pilih = await showModalBottomSheet<_AksiKelola>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _KelolaSheet(place: place),
    );

    if (pilih == null) return;

    switch (pilih) {
      case _AksiKelola.ubah:
        onEdit();
      case _AksiKelola.ubahStatus:
        onToggleStatus();
      case _AksiKelola.hapus:
        onDelete();
    }
  }
}

class _BarStatus extends StatelessWidget {
  const _BarStatus({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final aktif = place.isAktif;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: aktif ? AppColors.primaryOrange : AppColors.neutralBorder,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            aktif
                ? 'Tempat aktif dan tampil di pencarian'
                : 'Tempat nonaktif, tidak tampil di pencarian',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarHarga extends StatelessWidget {
  const _BarHarga({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga sewa',
          style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(place.hargaEfektif),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '/${place.durasiLabel.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _AksiKelola { ubah, ubahStatus, hapus }

class _KelolaSheet extends StatelessWidget {
  const _KelolaSheet({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
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
          Text(
            'Kelola Tempat',
            style: AppFonts.heading(
              fontSize: 20,
              weight: 600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            place.namaTempat,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          _KelolaAction(
            icon: Icons.edit_outlined,
            label: 'Ubah Data Tempat',
            keterangan: 'Ubah nama, harga, foto, dan keterangan tempat',
            onTap: () => Navigator.of(context).pop(_AksiKelola.ubah),
          ),
          _KelolaAction(
            icon: place.isAktif
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: place.isAktif ? 'Nonaktifkan Tempat' : 'Aktifkan Tempat',
            keterangan: place.isAktif
                ? 'Tempat tidak akan tampil untuk disewa'
                : 'Tempat kembali tampil untuk disewa',
            onTap: () => Navigator.of(context).pop(_AksiKelola.ubahStatus),
          ),
          _KelolaAction(
            icon: Icons.delete_outline,
            label: 'Hapus Tempat',
            keterangan: 'Tempat yang dihapus tidak dapat dikembalikan',
            warna: Theme.of(context).colorScheme.error,
            onTap: () => Navigator.of(context).pop(_AksiKelola.hapus),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KelolaAction extends StatelessWidget {
  const _KelolaAction({
    required this.icon,
    required this.label,
    required this.keterangan,
    required this.onTap,
    this.warna = AppColors.charcoal,
  });

  final IconData icon;
  final String label;
  final String keterangan;
  final VoidCallback onTap;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 20, color: warna),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: warna,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        keterangan,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
