import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/shimmer_loading.dart';

/// Home untuk role **Penyewa (TENANT)**:
///
/// - Mencari tempat berdasarkan nama/lokasi (backend mencocokkan nama,
///   deskripsi, kota, fasilitas, aturan).
/// - Filter kategori tempat usaha.
/// - Daftar tempat berstatus AKTIF (`GET /places`, data backend).
/// - Akses notifikasi. Aksi CRUD tempat tidak tersedia untuk Penyewa.
class TenantHomeScreen extends ConsumerStatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  ConsumerState<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends ConsumerState<TenantHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Menyimpan kata kunci setelah pengguna berhenti mengetik (350 ms).
  void _onSearchChanged(String value) {
    setState(() {}); // Memperbarui tampilan tombol bersihkan.
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

  /// Membuka bottom sheet pemilihan kategori (tombol filter pada search bar).
  Future<void> _showFilterSheet() async {
    final kategoriAktif = ref.read(tenantSearchProvider).kategori;

    final dipilih = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CategorySheet(kategoriAktif: kategoriAktif),
    );

    if (!mounted) return;
    if (dipilih != null) {
      ref.read(tenantSearchProvider.notifier).setKategori(dipilih);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final nama = user?.nama.trim() ?? '';
    final displayName = nama.isNotEmpty ? nama : 'Pengguna SPOTH';
    final kategoriAktif = ref.watch(tenantSearchProvider).kategori;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () => ref.read(tenantPlacesProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GreetingHeader(
                        displayName: displayName,
                        subtitle: 'Yuk, temukan tempat usaha',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const NotificationIconButton(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Temukan\nTempat Usahamu',
                  style: AppFonts.serif(
                    fontSize: 30,
                    weight: 600,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: AppColors.charcoal,
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
                          borderRadius: BorderRadius.circular(26),
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
                              const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.charcoal,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _showFilterSheet,
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.tune,
                            size: 22,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CategoryChips(kategoriAktif: kategoriAktif),
                const SizedBox(height: 18),
                const Text(
                  'Tempat Usaha',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                _PlaceGridSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet pemilihan kategori tempat.
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
            style: AppFonts.serif(
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

/// Chip kategori horizontal (Semua + 3 kategori dari backend).
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

/// Grid 2 kolom kartu tempat hasil pencarian/filter.
class _PlaceGridSection extends ConsumerWidget {
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
          itemBuilder: (context, index) => _PlaceGridCard(place: items[index]),
        );
      },
    );
  }
}

/// Kartu tempat (foto di atas, info di bawah) seperti referensi.
class _PlaceGridCard extends StatelessWidget {
  const _PlaceGridCard({required this.place});

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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    foto != null
                        ? Image.network(
                            foto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _PhotoPlaceholder(),
                          )
                        : const _PhotoPlaceholder(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          place.kategoriLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ),
                    if (promo != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PROMO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.namaTempat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.kota,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        Text(
                          '/${place.durasiLabel.toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 6),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.softBorder,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_repeat,
                            size: 11,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            place.durasiLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 11,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${place.foto.length}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.event_busy_outlined,
                            size: 11,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${place.jadwalTerpakai.length}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder konsisten ketika foto kosong atau gagal dimuat.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightOrange,
      child: Center(
        child: Icon(Icons.storefront, size: 34, color: AppColors.primaryOrange),
      ),
    );
  }
}
