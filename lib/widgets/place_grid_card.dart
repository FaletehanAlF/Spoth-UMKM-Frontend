import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';

class PlaceGridCard extends StatelessWidget {
  const PlaceGridCard({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    final foto = place.foto.isNotEmpty ? place.foto.first : null;
    final diskon = formatDiskonPersen(place.hargaNormal, place.hargaPromo);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/place-detail?id=${place.id}'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final tinggiFoto = (constraints.maxWidth * 0.62).clamp(
                    96.0,
                    150.0,
                  );

                  return SizedBox(
                    height: tinggiFoto,
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
                          child: _PhotoBadge(
                            label: place.kategoriLabel,
                            highlight: false,
                          ),
                        ),
                        if (diskon != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _PhotoBadge(label: diskon, highlight: true),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
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
                          height: 1.2,
                          color: AppColors.charcoal,
                        ),
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
                              place.kota,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(place.hargaEfektif),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: AppColors.charcoal,
                        ),
                      ),
                      if (diskon != null)
                        Text(
                          formatRupiah(place.hargaNormal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '/${place.durasiLabel.toLowerCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryOrange
            : AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: highlight ? AppColors.white : AppColors.charcoal,
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
      child: Center(
        child: Icon(Icons.storefront, size: 30, color: AppColors.primaryOrange),
      ),
    );
  }
}
