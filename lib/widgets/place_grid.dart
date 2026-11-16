import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/place_model.dart';
import 'place_grid_card.dart';
import 'shimmer_loading.dart';

class PlaceGrid extends StatelessWidget {
  const PlaceGrid({super.key, required this.places});

  final List<PlaceModel> places;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: PlaceGridMetrics.of(constraints.maxWidth).delegate,
          itemCount: places.length,
          itemBuilder: (context, index) => PlaceGridCard(place: places[index]),
        );
      },
    );
  }
}

class PlaceGridSkeleton extends StatelessWidget {
  const PlaceGridSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrik = PlaceGridMetrics.of(constraints.maxWidth);

        return ShimmerLoading(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: metrik.delegate,
            itemCount: count,
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: metrik.tinggiFoto,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: double.infinity,
                  color: AppColors.lightOrange,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 90,
                  color: AppColors.lightOrange,
                ),
                const Spacer(),
                Container(
                  height: 14,
                  width: 72,
                  color: AppColors.lightOrange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlaceGridMetrics {
  const PlaceGridMetrics({
    required this.kolom,
    required this.tinggiFoto,
    required this.extent,
  });

  factory PlaceGridMetrics.of(double lebarTersedia) {
    final kolom = lebarTersedia >= 900
        ? 4
        : lebarTersedia >= 600
        ? 3
        : lebarTersedia >= 340
        ? 2
        : 1;
    final lebarKartu = (lebarTersedia - 12 * (kolom - 1)) / kolom;
    final tinggiFoto = (lebarKartu * 0.62).clamp(96.0, 150.0);

    return PlaceGridMetrics(
      kolom: kolom,
      tinggiFoto: tinggiFoto,
      extent: tinggiFoto + 118,
    );
  }

  final int kolom;
  final double tinggiFoto;
  final double extent;

  SliverGridDelegateWithFixedCrossAxisCount get delegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kolom,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: extent,
      );
}
