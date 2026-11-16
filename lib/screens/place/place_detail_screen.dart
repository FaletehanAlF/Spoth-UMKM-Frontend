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
          ? const DetailSkeleton()
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
              child: EmptyState(
                icon: Icons.storefront,
                title: 'Tempat tidak ditemukan',
                message: 'Data tempat tidak tersedia di server.',
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
  });

  final PlaceModel place;
  final int fotoIndex;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPhoto(
            place: place,
            fotoIndex: fotoIndex,
            topInset: topInset,
            onFotoChanged: onFotoChanged,
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${place.alamat}, ${place.kota}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PriceBlock(place: place),
                  const SizedBox(height: 16),
                  _SpecRow(place: place),
                  const SizedBox(height: 18),
                  if (place.deskripsi != null &&
                      place.deskripsi!.isNotEmpty) ...[
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.deskripsi!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (place.fasilitasList.isNotEmpty) ...[
                    const Text(
                      'Fasilitas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final fasilitas in place.fasilitasList)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightOrange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              fasilitas,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (place.aturan != null && place.aturan!.isNotEmpty) ...[
                    const Text(
                      'Aturan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.aturan!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _BookedSchedules(place: place),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.place,
    required this.fotoIndex,
    required this.topInset,
    required this.onFotoChanged,
  });

  final PlaceModel place;
  final int fotoIndex;
  final double topInset;
  final ValueChanged<int> onFotoChanged;

  @override
  Widget build(BuildContext context) {
    final fotos = place.foto;
    final aktif = fotos.isNotEmpty
        ? fotos[fotoIndex.clamp(0, fotos.length - 1)]
        : null;

    return SizedBox(
      height: 280,
      width: double.infinity,
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
          if (fotos.length > 1)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final lebar = MediaQuery.sizeOf(context).width;
                  final keKanan = details.localPosition.dx > lebar / 2;
                  final baru = (fotoIndex + (keKanan ? 1 : -1)) % fotos.length;
                  onFotoChanged(baru < 0 ? fotos.length - 1 : baru);
                },
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
          if (fotos.length > 1)
            Positioned(
              bottom: 34,
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
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppColors.charcoal),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isAktif ? AppColors.primaryOrange : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isAktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          fontSize: 10,
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
    final promo = place.hasPromo ? place.hargaPromo : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRupiah(place.hargaEfektif),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
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
        if (promo != null) ...[
          const SizedBox(height: 2),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PROMO',
                  style: TextStyle(
                    fontSize: 9,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _SpecItem(
              icon: Icons.event_repeat,
              value: place.durasiLabel,
              label: 'Durasi',
            ),
          ),
          _SpecDivider(),
          Expanded(
            child: _SpecItem(
              icon: Icons.photo_library_outlined,
              value: '${place.foto.length}',
              label: 'Foto',
            ),
          ),
          _SpecDivider(),
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
        const SizedBox(height: 4),
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
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

class _SpecDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.softBorder);
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
        const Text(
          'Jadwal Sudah Dipesan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        if (place.jadwalTerpakai.isEmpty)
          const Text(
            'Belum ada jadwal yang terisi.',
            style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
          )
        else
          ...place.jadwalTerpakai.map(
            (jadwal) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_busy,
                    size: 17,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${formatDateString(jadwal.tanggalMulai)} – '
                      '${formatDateString(jadwal.tanggalSelesai)}'
                      '${jadwal.status == null ? '' : ' (${jadwal.status})'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
              label: Text(
                place.isAktif ? 'Nonaktifkan' : 'Aktifkan',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: acting ? null : onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: acting ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit', style: TextStyle(fontSize: 12)),
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
      child: content,
    );
  }
}
