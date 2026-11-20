import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/place_grid.dart';
import '../../widgets/riwayat_icon_button.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final summary = ref.watch(hostSummaryProvider);
    final places = ref.watch(myPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpothAppBar(
        title: const Text('Dashboard'),
        actions: const [NotificationIconButton(), RiwayatIconButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          await ref.read(hostSummaryProvider.notifier).refresh();
          await ref.read(myPlacesProvider.notifier).refresh();
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppWidth.page),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _WelcomeHeader(user: user),
                const SizedBox(height: 22),
                summary.when(
                  loading: () => const _SummarySkeleton(),
                  error: (error, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Gagal memuat ringkasan',
                    message:
                        'Periksa koneksi internet Anda lalu tarik ke bawah '
                        'untuk mencoba lagi.',
                    actionLabel: 'Coba Lagi',
                    onAction: () =>
                        ref.read(hostSummaryProvider.notifier).refresh(),
                  ),
                  data: (value) {
                    if (value == null) {
                      return const SizedBox.shrink();
                    }
                    return _SummaryGrid(value);
                  },
                ),
                const SizedBox(height: 22),
                _ActionsGrid(),
                const SizedBox(height: 22),
                places.when(
                  loading: () => const PlaceGridSkeleton(count: 3),
                  error: (error, _) => EmptyState(
                    icon: Icons.wifi_off,
                    title: 'Gagal memuat daftar tempat',
                    message:
                        'Periksa koneksi internet Anda lalu tarik ke bawah '
                        'untuk mencoba lagi.',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyPlaces();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempat Milikmu',
                          style: AppFonts.heading(
                            fontSize: 18,
                            weight: 700,
                            letterSpacing: -0.4,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PlaceGrid(places: items.take(4).toList()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final sapaan = namaDepan(user?.nama);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user?.foto != null && user!.foto!.isNotEmpty)
          ClipOval(
            child: Image.network(
              user!.foto!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _AvatarFallback(),
            ),
          )
        else
          const _AvatarFallback(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sapaan != null)
                Text(
                  'Halo, $sapaan',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Dashboard',
                style: AppFonts.heading(
                  fontSize: 28,
                  weight: 700,
                  height: 1.1,
                  letterSpacing: -0.8,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ringkasan keuangan & tempat Anda dalam satu pandangan.',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primaryInk,
        size: 24,
      ),
    );
  }
}

class _SummaryGrid extends ConsumerWidget {
  const _SummaryGrid(this.summary);

  final PlaceSummaryModel summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _SummaryStat(
        icon: Icons.payments_outlined,
        label: 'Pendapatan',
        value: formatRupiah(summary.totalPendapatan),
        tone: AppColors.primaryDeep,
        surface: AppColors.lightOrange,
      ),
      _SummaryStat(
        icon: Icons.check_circle_outline,
        label: 'Pemesanan Lunas',
        value: '${summary.pemesananLunas}',
      ),
      _SummaryStat(
        icon: Icons.pending,
        label: 'Pemesanan Menunggu',
        value: '${summary.pemesananMenunggu}',
        tone: AppColors.primaryInk,
        surface: AppColors.lightOrange,
      ),
      _SummaryStat(
        icon: Icons.storefront_outlined,
        label: 'Total Tempat',
        value: '${summary.totalTempat}',
      ),
      _SummaryStat(
        icon: Icons.check_circle_outline,
        label: 'Tempat Aktif',
        value: '${summary.tempatAktif}',
        tone: AppColors.sage,
        surface: AppColors.sageTint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final lebar = constraints.maxWidth;
        final cols = lebar >= 720 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisExtent: 104,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AppColors.primaryDeep,
    this.surface = AppColors.lightOrange,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 3),
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

class _ActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionCard(
          title: 'Kelola Tempat',
          subtitle: 'Lihat, edit, dan atur ketersediaan tempatmu',
          icon: Icons.storefront_outlined,
          onTap: () => ref
              .read(mainNavIndexProvider.notifier)
              .setTab(MainTab.kelolaTempat),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          title: 'Riwayat Penyewaan',
          subtitle: 'Lihat pesanan dan status setiap sewa',
          icon: Icons.receipt_long_outlined,
          onTap: () =>
              ref.read(mainNavIndexProvider.notifier).setTab(MainTab.booking),
        ),
      ],
    );
  }
}

class _ActionCard extends ConsumerWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.storefront,
      title: 'Belum ada tempat',
      message: 'Baru-baru ini belum ada tempat usaha yang Anda sewa.',
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(
            width: double.infinity,
            height: 104,
            radius: AppRadius.lg,
          ),
        ),
      ),
    );
  }
}
