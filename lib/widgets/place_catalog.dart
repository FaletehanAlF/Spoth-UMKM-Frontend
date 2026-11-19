import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/place_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/app_layout.dart';
import '../models/category_model.dart';
import '../providers/place_provider.dart';
import 'empty_state.dart';
import 'place_grid.dart';

class PlaceCatalog extends ConsumerStatefulWidget {
  const PlaceCatalog({super.key});

  @override
  ConsumerState<PlaceCatalog> createState() => _PlaceCatalogState();
}

class _PlaceCatalogState extends ConsumerState<PlaceCatalog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ref
          .read(placeServiceProvider)
          .listCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // Fallback ke kategori preset saat API gagal (mencegah crash).
    }
  }

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
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetContext) => _CategorySheet(
        kategoriAktif: kategoriAktif,
        categories: _categories,
      ),
    );

    if (dipilih != null) {
      ref.read(tenantSearchProvider.notifier).setKategori(dipilih);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriAktif = ref.watch(tenantSearchProvider).kategori;
    final jumlah = ref.watch(tenantPlacesProvider).value?.length;

    return RefreshIndicator(
      color: AppColors.primaryDeep,
      onRefresh: () => ref.read(tenantPlacesProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppWidth.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempat Usaha',
                  style: AppFonts.heading(
                    fontSize: 26,
                    weight: 700,
                    height: 1.15,
                    letterSpacing: -0.7,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jumlah != null
                      ? '$jumlah tempat usaha siap disewa'
                      : 'Temukan ruang yang pas untuk usahamu.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.softBorder),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
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
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: _showFilterSheet,
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.tune,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CategoryChips(
                  kategoriAktif: kategoriAktif,
                  categories: _categories,
                ),
                const SizedBox(height: 20),
                const _CatalogGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.kategoriAktif, this.categories});

  final String? kategoriAktif;
  final List<CategoryModel>? categories;

  static const _presetIkon = <String, IconData>{
    'LAPAK_USAHA': Icons.storefront,
    'TERAS_KOMERSIAL': Icons.deck,
    'BOOTH_EVENT': Icons.confirmation_number_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final items = <(String?, String, IconData)>[
      (null, 'Semua Kategori', Icons.apps),
      for (final item in categories ?? const <CategoryModel>[])
        (item.nama, item.nama, _presetIkon[item.nama] ?? Icons.storefront),
      if (kategoriAktif != null &&
          (categories?.any((c) => c.nama == kategoriAktif) ?? false))
        (null, 'Semua Kategori', Icons.apps), // duplicate-safe
    ];

    // Deduplicate by nama to keep the sheet clean.
    final seen = <String>{};
    final unique = items.where((entry) {
      final nama = entry.$2;
      if (seen.contains(nama)) return false;
      seen.add(nama);
      return true;
    }).toList();

    final nama = <String, String>{
      for (final entry in unique) entry.$1!.isEmpty ? '' : entry.$1!: entry.$2,
    };
    final ikon = <String, IconData>{
      for (final entry in unique) entry.$1!.isEmpty ? '' : entry.$1!: entry.$3,
    };
    final options = unique.map((entry) => entry.$1).toList();

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
              weight: 700,
              letterSpacing: -0.4,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          for (final option in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  ikon[option],
                  size: 18,
                  color: AppColors.primaryDeep,
                ),
              ),
              title: Text(
                nama[option] ?? '',
                style: const TextStyle(fontSize: 14.5),
              ),
              trailing: kategoriAktif == option
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryDeep,
                      size: 20,
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      color: AppColors.neutralBorder,
                      size: 20,
                    ),
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.kategoriAktif, this.categories});

  static const _ikon = <String, IconData>{
    'LAPAK_USAHA': Icons.storefront,
    'TERAS_KOMERSIAL': Icons.deck,
    'BOOTH_EVENT': Icons.confirmation_number_outlined,
  };

  final String? kategoriAktif;
  final List<CategoryModel>? categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pilih(String? kategori) {
      ref.read(tenantSearchProvider.notifier).setKategori(kategori);
    }

    Widget chip({
      required String? value,
      required String label,
      required IconData icon,
      required bool selected,
    }) {
      return Material(
        color: selected ? AppColors.primaryDeep : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => pilih(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primaryDeep : AppColors.softBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.white : AppColors.primaryDeep,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            value: null,
            label: 'Semua',
            icon: Icons.apps,
            selected: kategoriAktif == null,
          ),
          for (final item in categories ?? const <CategoryModel>[]) ...[
            const SizedBox(width: 8),
            chip(
              value: item.nama,
              label: item.nama,
              icon: _ikon[item.nama] ?? Icons.storefront,
              selected: kategoriAktif == item.nama,
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
      loading: () => const PlaceGridSkeleton(count: 6),
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
            message:
                'Coba ubah kata kunci atau kategori pencarian. '
                'Mungkin ada ruang lain yang lebih cocok.',
          );
        }

        return PlaceGrid(places: items);
      },
    );
  }
}
