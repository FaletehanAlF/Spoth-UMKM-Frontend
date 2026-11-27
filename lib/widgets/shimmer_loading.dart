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
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = constraints.maxWidth >= 700;
        final lebarKartu = duaKolom
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return ShimmerLoading(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: lebarKartu,
                  child: const _SkeletonCard(
                    child: Column(
                      children: [
                        Row(
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
                                  SizedBox(height: 6),
                                  _SkeletonBar(height: 11, width: 96),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            _SkeletonBar(height: 22, width: 74, radius: 12),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Spacer(),
                            _SkeletonBar(height: 15, width: 96),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Kerangka judul halaman (tulisan besar + garis bawah) yang ikut ber-shimmer.
///
/// Dipakai di bagian atas halaman saat daftar di bawahnya masih dimuat,
/// supaya shimmer tidak hanya muncul di kartu.
class PageTitleSkeleton extends StatelessWidget {
  const PageTitleSkeleton({super.key, this.subtitleWidth = 130});

  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBar(height: 18, width: 150),
          SizedBox(height: 8),
          _SkeletonBar(height: 12, width: subtitleWidth),
        ],
      ),
    );
  }
}

class RiwayatListSkeleton extends StatelessWidget {
  const RiwayatListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = constraints.maxWidth >= 700;
        final lebarKartu = duaKolom
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return ShimmerLoading(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: lebarKartu,
                  child: const _SkeletonCard(
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
            ],
          ),
        );
      },
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = MediaQuery.sizeOf(context).width >= AppWidth.sidebar;

        final hero = Container(
          height: duaKolom
              ? (constraints.maxWidth * 0.46 * 0.78).clamp(230.0, 430.0)
              : 240,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: duaKolom ? BorderRadius.circular(AppRadius.xl) : null,
          ),
        );

        const isi = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBar(height: 24, width: 230),
            SizedBox(height: 12),
            _SkeletonBar(height: 13, width: 176),
            SizedBox(height: 16),
            _SkeletonBar(height: 26, width: 148),
            SizedBox(height: 24),
            _SkeletonBar(height: 13, width: 84),
            SizedBox(height: 12),
            _SkeletonBar(height: 12, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBar(height: 12, width: 260),
            SizedBox(height: 24),
            _SkeletonBar(height: 13, width: 120),
            SizedBox(height: 12),
            _SkeletonBar(height: 12, width: double.infinity),
            SizedBox(height: 8),
            _SkeletonBar(height: 12, width: 210),
          ],
        );

        if (!duaKolom) {
          return ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hero,
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    child: isi,
                  ),
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

  static const _judulFoto = _SkeletonBar(height: 15, width: 96);
  static const _judulInfo = _SkeletonBar(height: 15, width: 132);
  static const _judulHarga = _SkeletonBar(height: 15, width: 104);

  static const _foto = _SkeletonBar(
    height: 120,
    width: double.infinity,
    radius: AppRadius.lg,
  );

  static const _paket = Column(
    children: [
      _SkeletonBar(height: 52, width: double.infinity, radius: 12),
      SizedBox(height: 12),
      _SkeletonBar(height: 52, width: double.infinity, radius: 12),
    ],
  );

  static const _info = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonBar(height: 52, width: double.infinity, radius: 12),
      SizedBox(height: 16),
      _SkeletonBar(height: 40, width: 220, radius: AppRadius.pill),
      SizedBox(height: 16),
      _SkeletonBar(height: 84, width: double.infinity, radius: 12),
      SizedBox(height: 16),
      _SkeletonBar(height: 52, width: double.infinity, radius: 12),
    ],
  );

  Widget _bagian(Widget judul, Widget isi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [judul, const SizedBox(height: 12), isi],
    );
  }

  @override
  Widget build(BuildContext context) {
    final duaKolom = MediaQuery.sizeOf(context).width >= AppWidth.sidebar;

    return ShimmerLoading(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: duaKolom ? AppWidth.page : AppWidth.form,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: duaKolom
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _bagian(_judulFoto, _foto),
                            const SizedBox(height: 24),
                            _bagian(_judulHarga, _paket),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 6, child: _bagian(_judulInfo, _info)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _bagian(_judulFoto, _foto),
                      const SizedBox(height: 24),
                      _bagian(_judulInfo, _info),
                      const SizedBox(height: 24),
                      _bagian(_judulHarga, _paket),
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
