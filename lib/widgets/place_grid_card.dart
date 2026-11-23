import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../core/utils/format.dart';
import '../models/place_model.dart';

class PlaceGridCard extends StatelessWidget {
  const PlaceGridCard({super.key, required this.place});

  final PlaceModel place;

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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final tinggiFoto = (constraints.maxWidth * 0.66).clamp(
                    100.0,
                    180.0,
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
                                    const PlacePhotoPlaceholder(),
                              )
                            : const PlacePhotoPlaceholder(),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _PhotoBadge(
                            label: place.kategoriLabel,
                            highlight: false,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.namaTempat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.15,
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
                              place.kecamatan,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              formatRupiah(place.harga),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: -0.2,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                          Text(
                            '/${place.durasiLabel.toLowerCase()}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryDeep : AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: highlight ? AppColors.white : AppColors.charcoal,
        ),
      ),
    );
  }
}

class PlacePhotoPlaceholder extends StatelessWidget {
  const PlacePhotoPlaceholder({super.key, this.caption});

  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.lightOrange),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront, size: 28, color: AppColors.primaryDeep),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



