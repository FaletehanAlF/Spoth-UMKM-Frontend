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
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tinggiHero = (constraints.maxWidth * 0.72).clamp(240.0, 420.0);

        return RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroGallery(
                  place: place,
                  fotoIndex: fotoIndex,
                  topInset: topInset,
                  lebar: constraints.maxWidth,
                  tinggi: tinggiHero,
                  onFotoChanged: onFotoChanged,
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: _DetailSheet(place: place),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroGallery extends StatelessWidget {
  const _HeroGallery({
    required this.place,
    required this.fotoIndex,
    required this.topInset,
    required this.lebar,
    required this.tinggi,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final double topInset;
  final double lebar;
  final double tinggi;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final aktif = fotos.isNotEmpty
        ? fotos[fotoIndex.clamp(0, fotos.length - 1)]
        : null;
    final adaNavigasi = fotos.length > 1;

    return SizedBox(
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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                  Color(0x4D000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          if (adaNavigasi)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final keKanan = details.localPosition.dx > lebar / 2;
                final baru = (fotoIndex + (keKanan ? 1 : -1)) % fotos.length;
                onFotoChanged(baru < 0 ? fotos.length - 1 : baru);
              },
            ),
          if (adaNavigasi)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _GalleryCue(icon: Icons.chevron_left),
                    _GalleryCue(icon: Icons.chevron_right),
                  ],
                ),
              ),
            ),
          Positioned(
            top: topInset + 12,
            left: 16,
            child: _CircleButton(
              icon: Icons.arrow_back,
              tooltip: 'Kembali',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (adaNavigasi)
            Positioned(
              bottom: 36,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${fotoIndex + 1} / ${fotos.length}',
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
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.white),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(Icons.storefront, size: 64, color: AppColors.primaryOrange),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
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
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 21, color: AppColors.charcoal),
          ),
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoBadge(label: place.kategoriLabel),
                    const SizedBox(width: 8),
                    _StatusBadge(isAktif: place.isAktif),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
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
                const SizedBox(height: 18),
                _PriceBlock(place: place),
                const SizedBox(height: 18),
                _SpecRow(place: place),
                if (namaHost != null && namaHost.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _HostRow(namaHost: namaHost),
                ],
                if (place.deskripsi != null &&
                    place.deskripsi!.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionTitle('Deskripsi'),
                  const SizedBox(height: 8),
                  Text(
                    place.deskripsi!.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                if (place.fasilitasList.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionTitle('Fasilitas'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final fasilitas in place.fasilitasList)
                        _FasilitasChip(label: fasilitas),
                    ],
                  ),
                ],
                if (place.aturan != null && place.aturan!.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionTitle('Aturan'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightOrange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            place.aturan!.trim(),
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
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
            ),
          ),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
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
          style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText),
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
    if (isTenant) {
      if (place.isAktif) {
        content = SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/booking-form?id=${place.id}'),
            icon: const Icon(Icons.event_available),
            label: const Text('Sewa Tempat Ini'),
          ),
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
    } else if (isOwner) {
      content = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: acting ? null : onToggleStatus,
              icon: Icon(
                place.isAktif
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: _ButtonLabel(
                place.isAktif ? 'Nonaktifkan' : 'Aktifkan',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: acting ? null : onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const _ButtonLabel('Hapus'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: acting ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const _ButtonLabel('Edit'),
            ),
          ),
        ],
      );
    } else {
      content = const SizedBox.shrink();
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
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}
