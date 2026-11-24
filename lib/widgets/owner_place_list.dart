import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../core/theme/app_fonts.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import 'empty_state.dart';
import 'shimmer_loading.dart';

class OwnerPlaceList extends ConsumerStatefulWidget {
  const OwnerPlaceList({super.key});

  @override
  ConsumerState<OwnerPlaceList> createState() => _OwnerPlaceListState();
}

class _OwnerPlaceListState extends ConsumerState<OwnerPlaceList> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(ownerPlacesFilterProvider.notifier).setKeyword(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    ref.read(ownerPlacesFilterProvider.notifier).setKeyword('');
  }

  void _resetFilter() {
    _searchController.clear();
    setState(() {});
    ref.read(ownerPlacesFilterProvider.notifier).setKeyword('');
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(myPlacesProvider);
    final filter = ref.watch(ownerPlacesFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        const SizedBox(height: 14),
        places.when(
          loading: () => const PlaceListSkeleton(count: 3),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat daftar tempat',
            message: 'Periksa koneksi internet Anda lalu tarik ke bawah untuk mencoba lagi.',
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyPlaces(
                adaFilter: filter.keyword.trim().isNotEmpty,
                onReset: _resetFilter,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final duaKolom = constraints.maxWidth >= 980;
                final lebarKartu = duaKolom
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items.length} tempat',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: lebarKartu,
                            child: _OwnerPlaceCard(place: item),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.darkText),
              decoration: const InputDecoration(
                hintText: 'Cari nama atau kecamatan tempat...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Bersihkan',
              color: AppColors.secondaryText,
              onPressed: onClear,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces({required this.adaFilter, required this.onReset});

  final bool adaFilter;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tinggi = MediaQuery.sizeOf(context).height * 0.5;

    if (adaFilter) {
      return SizedBox(
        height: tinggi,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 40,
                  color: AppColors.primaryDeep,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tidak ada tempat yang cocok',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Coba kata kunci lain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: tinggi,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 40, color: AppColors.primaryDeep),
              SizedBox(height: 12),
              Text(
                'Belum ada tempat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tambahkan tempat usaha pertama Anda dengan tombol "Tambah Tempat".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPlaceCard extends ConsumerStatefulWidget {
  const _OwnerPlaceCard({required this.place});

  final PlaceModel place;

  @override
  ConsumerState<_OwnerPlaceCard> createState() => _OwnerPlaceCardState();
}

class _OwnerPlaceCardState extends ConsumerState<_OwnerPlaceCard> {
  bool _acting = false;

  PlaceModel get place => widget.place;

  Future<void> _delete() async {
    if (_acting) return;

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
              style: TextStyle(color: AppColors.danger),
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
    if (_acting) return;

    final saved = await context.push('/place-form?id=${place.id}');
    if (saved == true && mounted) {
      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();
    }
  }

  Future<void> _showKelolaSheet() async {
    final pilih = await showModalBottomSheet<_AksiKelola>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _KelolaSheet(place: place),
    );

    if (pilih == null) return;

    switch (pilih) {
      case _AksiKelola.ubah:
        await _edit();
      case _AksiKelola.hapus:
        await _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/place-detail?id=${place.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: foto != null
                      ? Image.network(
                          foto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                        )
                      : const _PhotoPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.namaTempat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${place.kategoriLabel} - ${place.kecamatan}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(place.harga),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      'per ${place.durasiLabel.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (place.sudahDiSewa) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_clock,
                              size: 12,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tempat sudah di sewa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _acting ? null : _showKelolaSheet,
                icon: const Icon(Icons.more_vert),
                tooltip: place.sudahDiSewa
                    ? 'Tempat sudah di sewa'
                    : 'Kelola Tempat',
                color: place.sudahDiSewa
                    ? AppColors.danger
                    : AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.lightOrange),
      child: const Icon(
        Icons.storefront,
        size: 26,
        color: AppColors.primaryDeep,
      ),
    );
  }
}

enum _AksiKelola { ubah, hapus }

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
      child: SingleChildScrollView(
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
              'Aksi Tempat',
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
              icon: Icons.delete_outline,
              label: 'Hapus Tempat',
              keterangan: 'Tempat yang dihapus tidak dapat dikembalikan',
              warna: AppColors.danger,
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





