import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';
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
    final notifier = ref.read(ownerPlacesFilterProvider.notifier);
    notifier.setKeyword('');
    notifier.setStatus(null);
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
        const SizedBox(height: 12),
        _StatusFilterChips(
          statusAktif: filter.status,
          onChanged: (status) =>
              ref.read(ownerPlacesFilterProvider.notifier).setStatus(status),
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
                adaFilter:
                    filter.keyword.trim().isNotEmpty || filter.status != null,
                onReset: _resetFilter,
              );
            }

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
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _OwnerPlaceCard(place: items[i]),
                ],
              ],
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
        borderRadius: BorderRadius.circular(25),
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
                hintText: 'Cari nama atau kota tempat...',
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

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.statusAktif,
    required this.onChanged,
  });

  final String? statusAktif;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip({required String? value, required String label}) {
      final selected = statusAktif == value;

      return Material(
        color: selected ? AppColors.primaryOrange : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primaryOrange
                    : AppColors.softBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.charcoal,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(value: null, label: 'Semua'),
          const SizedBox(width: 10),
          chip(value: 'AKTIF', label: 'Aktif'),
          const SizedBox(width: 10),
          chip(value: 'NONAKTIF', label: 'Nonaktif'),
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
    if (adaFilter) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ada tempat yang cocok',
        message: 'Coba kata kunci lain atau pilih filter status yang berbeda.',
        actionLabel: 'Reset Filter',
        onAction: onReset,
      );
    }

    return const EmptyState(
      icon: Icons.storefront,
      title: 'Belum ada tempat',
      message:
          'Tambahkan tempat usaha pertama Anda dengan tombol "Tambah Tempat".',
    );
  }
}

class _OwnerPlaceCard extends StatelessWidget {
  const _OwnerPlaceCard({required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;
    final promo = place.hasPromo ? place.hargaPromo : null;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/place-detail?id=${place.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
                        const SizedBox(width: 8),
                        _StatusBadge(isAktif: place.isAktif),
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
                            '${place.kategoriLabel} • ${place.kota}',
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            formatRupiah(place.hargaEfektif),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        if (promo != null)
                          Text(
                            formatRupiah(place.hargaNormal),
                            style: const TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'per ${place.durasiLabel.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAktif ? AppColors.primaryOrange : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isAktif ? AppColors.white : AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightOrange,
      child: Icon(Icons.storefront, size: 26, color: AppColors.primaryOrange),
    );
  }
}
