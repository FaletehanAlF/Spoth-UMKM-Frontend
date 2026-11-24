import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../shimmer_loading.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final sapaan = namaDepan(user?.nama);

    return Row(
      children: [
        _Avatar(foto: user?.foto),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sapaan != null)
                Text(
                  'Halo, $sapaan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              const SizedBox(height: 2),
              const Text(
                'Ringkasan Usaha',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.foto});

  final String? foto;

  @override
  Widget build(BuildContext context) {
    final url = foto?.trim() ?? '';

    if (url.isEmpty) return const _AvatarKosong();

    return ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _AvatarKosong(),
      ),
    );
  }
}

class _AvatarKosong extends StatelessWidget {
  const _AvatarKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 22,
        color: AppColors.primaryInk,
      ),
    );
  }
}

int jumlahKolomStatistik(double lebar) => lebar >= 880 ? 4 : 2;

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.summary});

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Statistik(
        ikon: Icons.account_balance_wallet_outlined,
        label: 'Pendapatan',
        nilai: formatRupiah(summary.totalPendapatan),
      ),
      _Statistik(
        ikon: Icons.storefront_outlined,
        label: 'Total Tempat',
        nilai: '${summary.totalTempat}',
      ),
      _Statistik(
        ikon: Icons.event_available_outlined,
        label: 'Penyewaan',
        nilai: '${summary.totalPemesanan}',
      ),
      _Statistik(
        ikon: Icons.check_circle_outline,
        label: 'Penyewaan Lunas',
        nilai: '${summary.pemesananLunas}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final kolom = jumlahKolomStatistik(constraints.maxWidth);
        final jarak = constraints.maxWidth < 520 ? 10.0 : 14.0;
        final lebar = (constraints.maxWidth - jarak * (kolom - 1)) / kolom;

        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: [
            for (final item in items)
              SizedBox(width: lebar, child: _KotakStatistik(data: item)),
          ],
        );
      },
    );
  }
}

class _Statistik {
  const _Statistik({
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  final IconData ikon;
  final String label;
  final String nilai;
}

class _KotakStatistik extends StatelessWidget {
  const _KotakStatistik({required this.data});

  final _Statistik data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.ikon, size: 18, color: AppColors.primaryDeep),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.nilai,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kolom = jumlahKolomStatistik(constraints.maxWidth);
        final jarak = constraints.maxWidth < 520 ? 10.0 : 14.0;
        final lebar = (constraints.maxWidth - jarak * (kolom - 1)) / kolom;

        return ShimmerLoading(
          child: Wrap(
            spacing: jarak,
            runSpacing: jarak,
            children: [
              for (var i = 0; i < 4; i++)
                SizedBox(
                  width: lebar,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.softBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 34, height: 34, radius: 10),
                        SizedBox(height: 14),
                        ShimmerBox(width: 88, height: 20),
                        SizedBox(height: 8),
                        ShimmerBox(width: 62, height: 12),
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
