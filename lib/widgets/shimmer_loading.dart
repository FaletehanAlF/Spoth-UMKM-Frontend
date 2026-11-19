import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightOrange,
      highlightColor: AppColors.white,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class PlaceListSkeleton extends StatelessWidget {
  const PlaceListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 160,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: 110,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 13,
                          width: 90,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SummarySkeleton extends StatelessWidget {
  const SummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 176,
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 140,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 11,
                          width: 80,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookingListSkeleton extends StatelessWidget {
  const BookingListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(height: 15, width: 140, color: AppColors.white),
                      const Spacer(),
                      Container(height: 14, width: 70, color: AppColors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: AppColors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 220, color: AppColors.white),
                  const SizedBox(height: 10),
                  Container(height: 15, width: 100, color: AppColors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = constraints.maxWidth >= 840;

        final hero = Container(
          height: duaKolom
              ? (constraints.maxWidth * 0.46 * 0.78).clamp(230.0, 430.0)
              : 240,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: duaKolom ? BorderRadius.circular(AppRadius.xl) : null,
          ),
        );

        final isi = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(duaKolom ? AppRadius.xl : 0),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBar(height: 24, width: 96, radius: 8),
                  SizedBox(width: 8),
                  _SkeletonBar(height: 24, width: 72, radius: 8),
                ],
              ),
              SizedBox(height: 14),
              _SkeletonBar(height: 24, width: 220),
              SizedBox(height: 10),
              _SkeletonBar(height: 13, width: 180),
              SizedBox(height: 18),
              _SkeletonBar(height: 28, width: 150),
              SizedBox(height: 18),
              _SkeletonBar(
                height: 76,
                width: double.infinity,
                radius: AppRadius.lg,
              ),
              SizedBox(height: 22),
              _SkeletonBar(height: 14, width: 90),
              SizedBox(height: 10),
              _SkeletonBar(height: 12, width: double.infinity),
              SizedBox(height: 6),
              _SkeletonBar(height: 12, width: 260),
            ],
          ),
        );

        if (!duaKolom) {
          return ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hero,
                Transform.translate(offset: const Offset(0, -22), child: isi),
              ],
            ),
          );
        }

        return ShimmerLoading(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 46, child: hero),
                const SizedBox(width: 24),
                Expanded(flex: 54, child: isi),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.height,
    required this.width,
    this.radius = 8,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class PlaceFormSkeleton extends StatelessWidget {
  const PlaceFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
