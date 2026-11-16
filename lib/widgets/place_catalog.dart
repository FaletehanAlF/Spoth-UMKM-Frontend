import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import 'empty_state.dart';
import 'place_grid_card.dart';
import 'shimmer_loading.dart';

class PlaceCatalog extends ConsumerStatefulWidget {
  const PlaceCatalog({super.key});

  @override
  ConsumerState<PlaceCatalog> createState() => _PlaceCatalogState();
}

class _PlaceCatalogState extends ConsumerState<PlaceCatalog> {
  final TextEditingController _searchController = TextEditingController();
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
      ref.read(tenantSearchProvider.notifier).setKeyword(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    ref.read(tenantSearchProvider.notifier).setKeyword('');
  }

  Future<void> _showFilterSheet() async {
    final kategoriAktif = ref.read(tenantSearchProvider).kategori;

    final dipilih = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CategorySheet(kategoriAktif: kategoriAktif),
    );

    if (dipilih != null) {
      ref.read(tenantSearchProvider.notifier).setKategori(dipilih);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriAktif = ref.watch(tenantSearchProvider).kategori;

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () => ref.read(tenantPlacesProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkText,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari tempat, kota, atau lokasi...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Bersihkan',
                            color: AppColors.secondaryText,
                            onPressed: _clearSearch,
                          )
                        else
                          const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.charcoal,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _showFilterSheet,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(Icons.tune, size: 20, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CategoryChips(kategoriAktif: kategoriAktif),
            const SizedBox(height: 14),
            const Text(
              'Tempat Usaha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            const _CatalogGrid(),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.kategoriAktif});

  final String? kategoriAktif;

  static const _options = <String?>[
    null,
    'LAPAK_USAHA',
    'TERAS_KOMERSIAL',
    'BOOTH_EVENT',
  ];

  @override
  Widget build(BuildContext context) {
    final nama = <String?, String>{
      null: 'Semua Kategori',
      'LAPAK_USAHA': 'Lapak Usaha',
      'TERAS_KOMERSIAL': 'Teras Komersial',
      'BOOTH_EVENT': 'Booth Event',
    };
    final ikon = <String?, IconData>{
      null: Icons.apps,
      'LAPAK_USAHA': Icons.storefront,
      'TERAS_KOMERSIAL': Icons.deck,
      'BOOTH_EVENT': Icons.confirmation_number_outlined,
    };

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
            'Pilih kategori',
            style: AppFonts.heading(
              fontSize: 20,
              weight: 600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          for (final option in _options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(ikon[option], color: AppColors.primaryOrange),
              title: Text(
                nama[option] ?? '',
                style: const TextStyle(fontSize: 15),
              ),
              trailing: kategoriAktif == option
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryOrange,
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      color: AppColors.softBorder,
                    ),
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.kategoriAktif});

  final String? kategoriAktif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pilih(String? kategori) {
      ref.read(tenantSearchProvider.notifier).setKategori(kategori);
    }

    Widget chip({
      required String? value,
      required String label,
      required bool selected,
    }) {
      return Material(
        color: selected ? AppColors.primaryOrange : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => pilih(value),
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
          chip(value: null, label: 'Semua', selected: kategoriAktif == null),
          for (final kategori in PlaceModel.kategoriValues) ...[
            const SizedBox(width: 10),
            chip(
              value: kategori,
              label: PlaceModel.kategoriLabels[kategori] ?? kategori,
              selected: kategoriAktif == kategori,
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogGrid extends ConsumerWidget {
  const _CatalogGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(tenantPlacesProvider);

    return places.when(
      loading: () => const PlaceListSkeleton(count: 4),
      error: (error, _) => EmptyState(
        icon: Icons.wifi_off,
        title: 'Gagal memuat tempat',
        message: 'Periksa koneksi internet Anda lalu coba lagi.',
        actionLabel: 'Coba Lagi',
        onAction: () => ref.read(tenantPlacesProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.storefront,
            title: 'Tempat tidak ditemukan',
            message: 'Coba ubah kata kunci atau kategori pencarian.',
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => PlaceGridCard(place: items[index]),
        );
      },
    );
  }
}
