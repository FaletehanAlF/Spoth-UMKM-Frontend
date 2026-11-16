import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/format.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sapaan = namaDepan(
      ref.watch(authNotifierProvider.select((state) => state.user?.nama)),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SpothAppBar(
        title: const Text(
          'Spoth UMKM',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [NotificationIconButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async {
          await ref.read(myPlacesProvider.notifier).refresh();
          await ref.read(hostSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sapaan != null) ...[
                    Text(
                      'Halo, $sapaan',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'Ringkasan Usaha',
                    style: AppFonts.heading(
                      fontSize: 26,
                      weight: 600,
                      height: 1.15,
                      letterSpacing: -0.4,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final lebar = constraints.maxWidth;
                      final ringkasan = <Widget>[
                        const _SummarySection(),
                        const SizedBox(height: 12),
                        _ManagePlacesCard(
                          onTap: () => ref.read(
                            mainNavIndexProvider.notifier,
                          ).setTab(1),
                        ),
                      ];

                      if (lebar < 720) {
                        return Column(children: ringkasan);
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 3, child: _SummarySection()),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _ManagePlacesCard(
                              onTap: () => ref.read(
                                mainNavIndexProvider.notifier,
                              ).setTab(1),
                            ),
                          ),
                        ],
                      );
                    },
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

class _ManagePlacesCard extends StatelessWidget {
  const _ManagePlacesCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lightOrange,
                child: Icon(
                  Icons.storefront,
                  color: AppColors.primaryOrange,
                  size: 22,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempat Saya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Lihat, edit, dan kelola semua tempat usaha Anda',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hostSummaryProvider);

    return summary.when(
      loading: () => const SummarySkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat ringkasan',
        message:
            'Periksa koneksi internet Anda lalu tarik ke bawah untuk mencoba lagi.',
      ),
      data: (value) {
        if (value == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _RevenueCard(
              pendapatan: value.totalPendapatan,
              menungguBayar: value.pemesananMenunggu,
              lunas: value.pemesananLunas,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.storefront,
                    label: 'Total Tempat',
                    value: '${value.totalTempat}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Tempat Aktif',
                    value: '${value.tempatAktif}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.pendapatan,
    required this.menungguBayar,
    required this.lunas,
  });

  final double pendapatan;
  final int menungguBayar;
  final int lunas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 17,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Pendapatan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(pendapatan),
              style: AppFonts.heading(
                fontSize: 28,
                weight: 700,
                letterSpacing: -0.6,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.softBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RevenueFact(
                  label: 'Menunggu Bayar',
                  value: '$menungguBayar',
                ),
              ),
              Expanded(
                child: _RevenueFact(label: 'Lunas', value: '$lunas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueFact extends StatelessWidget {
  const _RevenueFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
