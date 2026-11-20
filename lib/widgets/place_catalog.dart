import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/place_service.dart';
import '../core/constants/category_style.dart';
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
      final categories = await ref.read(placeServiceProvider).listCategories();
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

    final dipilih = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetContext) =>
          _CategorySheet(kategoriAktif: kategoriAktif, categories: _categories),
    );

    // `null` = sheet ditutup tanpa memilih; string kosong = "Semua Kategori".
    if (dipilih != null) {
      ref
          .read(tenantSearchProvider.notifier)
          .setKategori(dipilih.isEmpty ? null : dipilih);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriAktif = ref.watch(tenantSearchProvider).kategori;

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
                const SizedBox(height: 8),
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
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: _showFilterSheet,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.softBorder),
                          ),
                          child: const Icon(
                            Icons.tune,
                            size: 20,
                            color: AppColors.primaryDeep,
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

  @override
  Widget build(BuildContext context) {
    // Sentinel string kosong dipakai untuk "Semua Kategori" agar bisa
    // dibedakan dari `null` yang berarti sheet ditutup tanpa memilih.
    final aktif = kategoriAktif ?? '';
    final items = <(String, String, IconData)>[
      ('', 'Semua Kategori', Icons.apps),
      for (final item in categories ?? const <CategoryModel>[])
        (item.nama, categoryLabel(item.nama), categoryIcon(item.nama)),
    ];

    // Deduplicate by nilai agar sheet tetap bersih.
    final seen = <String>{};
    final unique = items.where((entry) => seen.add(entry.$1)).toList();

    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in unique)
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
                            option.$3,
                            size: 18,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        title: Text(
                          option.$2,
                          style: const TextStyle(fontSize: 14.5),
                        ),
                        trailing: aktif == option.$1
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
                        onTap: () => Navigator.of(context).pop(option.$1),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.kategoriAktif, this.categories});

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
              label: categoryLabel(item.nama),
              icon: categoryIcon(item.nama),
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
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront,
                  size: 40,
                  color: AppColors.primaryDeep,
                ),
                SizedBox(height: 12),
                Text(
                  'Tempat tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Coba ubah kata kunci atau kategori pencarian. '
                  'Mungkin ada ruang lain yang lebih cocok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          );
        }

        return PlaceGrid(places: items);
      },
    );
  }
}
