import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opasitas = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opasitas, child: widget.child);
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
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              child: Row(
                children: [
                  _SkeletonBar(height: 84, width: 84, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBar(height: 14, width: 160),
                        SizedBox(height: 8),
                        _SkeletonBar(height: 12, width: 110),
                        SizedBox(height: 8),
                        _SkeletonBar(height: 13, width: 90),
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
    return const ShimmerLoading(
      child: Column(
        children: [
          _SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBar(height: 12, width: 96),
                SizedBox(height: 14),
                _SkeletonBar(height: 28, width: 168),
                SizedBox(height: 12),
                _SkeletonBar(height: 12, width: double.infinity),
                SizedBox(height: 8),
                _SkeletonBar(height: 12, width: 210),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SkeletonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(height: 22, width: 64),
                      SizedBox(height: 10),
                      _SkeletonBar(height: 11, width: 88),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SkeletonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(height: 22, width: 56),
                      SizedBox(height: 10),
                      _SkeletonBar(height: 11, width: 78),
                    ],
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
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(height: 40, width: 40, radius: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBar(height: 13, width: 140),
                        SizedBox(height: 8),
                        _SkeletonBar(height: 11, width: double.infinity),
                        SizedBox(height: 6),
                        _SkeletonBar(height: 11, width: 82),
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
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(height: 56, width: 56, radius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBar(height: 14, width: 148),
                            SizedBox(height: 8),
                            _SkeletonBar(height: 11, width: 118),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      _SkeletonBar(height: 20, width: 62, radius: 8),
                    ],
                  ),
                  SizedBox(height: 12),
                  _SkeletonBar(height: 11, width: 210),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      _SkeletonBar(height: 15, width: 92),
                      Spacer(),
                      _SkeletonBar(height: 30, width: 74, radius: 8),
                    ],
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

class RiwayatListSkeleton extends StatelessWidget {
  const RiwayatListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          count,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(height: 72, width: 72, radius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBar(height: 15, width: 162),
                            SizedBox(height: 8),
                            _SkeletonBar(height: 11, width: 128),
                            SizedBox(height: 6),
                            _SkeletonBar(height: 11, width: 96),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      _SkeletonBar(height: 22, width: 76, radius: 8),
                    ],
                  ),
                  SizedBox(height: 12),
                  _SkeletonBar(height: 11, width: 190),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      _SkeletonBar(height: 16, width: 104),
                      Spacer(),
                      _SkeletonBar(height: 32, width: 86, radius: 8),
                    ],
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

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = constraints.maxWidth >= AppWidth.twoColumn;

        final hero = Container(
          height: duaKolom
              ? (constraints.maxWidth * 0.46 * 0.78).clamp(230.0, 430.0)
              : 240,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: duaKolom ? BorderRadius.circular(AppRadius.xl) : null,
          ),
        );

        const isi = _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBar(height: 22, width: 88, radius: 6),
                  SizedBox(width: 8),
                  _SkeletonBar(height: 22, width: 68, radius: 6),
                ],
              ),
              SizedBox(height: 16),
              _SkeletonBar(height: 24, width: 230),
              SizedBox(height: 12),
              _SkeletonBar(height: 13, width: 176),
              SizedBox(height: 20),
              _SkeletonBar(height: 26, width: 148),
              SizedBox(height: 22),
              _SkeletonBar(height: 72, width: double.infinity, radius: 16),
              SizedBox(height: 24),
              _SkeletonBar(height: 13, width: 84),
              SizedBox(height: 12),
              _SkeletonBar(height: 12, width: double.infinity),
              SizedBox(height: 8),
              _SkeletonBar(height: 12, width: 260),
              SizedBox(height: 8),
              _SkeletonBar(height: 12, width: 210),
              SizedBox(height: 24),
              _SkeletonBar(height: 46, width: double.infinity, radius: 12),
            ],
          ),
        );

        if (!duaKolom) {
          return ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hero,
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isi,
                ),
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
                const Expanded(flex: 54, child: isi),
              ],
            ),
          ),
        );
      },
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
          constraints: const BoxConstraints(maxWidth: AppWidth.form),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBar(height: 13, width: 88),
                SizedBox(height: 10),
                _SkeletonBar(
                  height: 140,
                  width: double.infinity,
                  radius: AppRadius.lg,
                ),
                SizedBox(height: 24),
                _SkeletonBar(height: 13, width: 104),
                SizedBox(height: 10),
                _SkeletonBar(height: 52, width: double.infinity, radius: 12),
                SizedBox(height: 18),
                _SkeletonBar(height: 13, width: 76),
                SizedBox(height: 10),
                _SkeletonBar(height: 52, width: double.infinity, radius: 12),
                SizedBox(height: 18),
                _SkeletonBar(height: 13, width: 92),
                SizedBox(height: 10),
                _SkeletonBar(height: 96, width: double.infinity, radius: 12),
                SizedBox(height: 24),
                _SkeletonBar(height: 13, width: 118),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBar(
                        height: 52,
                        width: double.infinity,
                        radius: 12,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SkeletonBar(
                        height: 52,
                        width: double.infinity,
                        radius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: child,
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.height,
    required this.width,
    this.radius = 6,
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
        color: AppColors.neutralBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
