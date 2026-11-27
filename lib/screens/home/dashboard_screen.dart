import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/dashboard/dashboard_panels.dart';
import '../../widgets/dashboard/dashboard_summary.dart';
import '../../widgets/dashboard/revenue_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spoth_app_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final summary = ref.watch(hostSummaryProvider);

    Future<void> muatUlang() async {
      await ref.read(hostSummaryProvider.notifier).refresh();
      await ref.read(bookingsProvider.notifier).refresh();
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: muatUlang,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppWidth.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(user: user),
                    const SizedBox(height: AppSpacing.xxl),
                    summary.when(
                      loading: () => const DashboardStatsSkeleton(),
                      error: (error, _) => EmptyState(
                        icon: Icons.wifi_off,
                        title: 'Gagal memuat ringkasan',
                        message:
                            'Koneksi ke server terputus. Periksa internetmu '
                            'lalu coba lagi.',
                        actionLabel: 'Coba lagi',
                        onAction: muatUlang,
                      ),
                      data: (value) {
                        if (value == null) {
                          return EmptyState(
                            icon: Icons.storefront_outlined,
                            title: 'Belum ada ringkasan',
                            message:
                                'Tambahkan tempat usaha pertama untuk mulai '
                                'melihat ringkasan di sini.',
                            actionLabel: 'Muat ulang',
                            onAction: muatUlang,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DashboardStats(summary: value),
                            const SizedBox(height: AppSpacing.xl),
                            RevenueSection(summary: value),
                            const SizedBox(height: AppSpacing.xxl),
                            const _Judul(teks: 'Aksi cepat'),
                            const SizedBox(height: AppSpacing.md),
                            const QuickActions(),
                            const SizedBox(height: AppSpacing.xxl),
                            const RecentBookings(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }
}
