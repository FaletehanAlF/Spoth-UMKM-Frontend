import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';

/// Kartu tempat untuk Penyewa (foto di atas, info di bawah).
///
/// Dipakai bersama oleh Beranda Penyewa (preview) dan tab Tempat
/// (katalog penuh), supaya tampilannya selalu sama.
class PlaceGridCard extends StatelessWidget {
  const PlaceGridCard({super.key, required this.place});

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
