import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import 'empty_state.dart';
import 'shimmer_loading.dart';

/// Daftar tempat milik **Pemilik (HOST)** yang sedang login
/// (`GET /places/mine`). Dipakai pada tab Tempat.
///
/// Hanya menampilkan tempat milik akun yang login — tempat milik pemilik
/// lain tidak pernah ditampilkan.
class OwnerPlaceList extends ConsumerWidget {
  const OwnerPlaceList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(myPlacesProvider);

    return places.when(
      loading: () => const PlaceListSkeleton(count: 3),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat daftar tempat',
        message: 'Periksa koneksi internet Anda lalu tarik ke bawah untuk mencoba lagi.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.storefront,
              title: 'Belum ada tempat',
              message:
                  'Tambahkan tempat usaha pertama Anda dengan tombol tambah '
                  'di kanan atas.',
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _OwnerPlaceCard(place: items[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Kartu tempat milik Pemilik; ketuk untuk membuka detail
/// (edit/hapus/status).
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

/// Badge status tempat (AKTIF / NONAKTIF) sesuai data backend.
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

/// Placeholder konsisten ketika foto kosong atau gagal dimuat.
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
