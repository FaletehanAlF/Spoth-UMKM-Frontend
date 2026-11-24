import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/notification_model.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/booking_provider.dart';
import 'package:spoth_umkm/providers/notification_provider.dart';
import 'package:spoth_umkm/providers/place_provider.dart';
import 'package:spoth_umkm/providers/riwayat_provider.dart';
import 'package:spoth_umkm/screens/home/dashboard_screen.dart';

class FakeAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: '1',
      nama: 'Host Contoh',
      email: 'host@spoth.test',
      role: 'HOST',
      createdAt: DateTime(2026, 1, 1),
    ),
    token: 'token-uji',
  );
}

class FakeSummary extends HostSummaryNotifier {
  FakeSummary(this.summary);

  final PlaceSummaryModel summary;

  @override
  Future<PlaceSummaryModel?> build() async => summary;
}

class FakeBookings extends BookingsNotifier {
  @override
  Future<List<BookingModel>> build() async => const [];
}

class FakeNotif extends NotificationSummaryNotifier {
  @override
  Future<NotificationSummaryModel?> build() async =>
      const NotificationSummaryModel(total: 0, belumDibaca: 0);
}

class FakeRiwayat extends RiwayatBadgeNotifier {
  @override
  Future<int> build() async => 0;
}

PlaceSummaryModel summaryNol({List<MonthlyRevenueModel>? bulanan}) {
  return PlaceSummaryModel(
    totalTempat: 1,
    totalPemesanan: 0,
    pemesananMenunggu: 0,
    pemesananLunas: 0,
    totalPendapatan: 0,
    totalKomisi: 0,
    pendapatanBulanan: bulanan,
  );
}

Future<void> tampilkanDashboard(
  WidgetTester tester,
  double lebar,
  PlaceSummaryModel summary,
) async {
  tester.view.physicalSize = Size(lebar, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuth.new),
        hostSummaryProvider.overrideWith(() => FakeSummary(summary)),
        bookingsProvider.overrideWith(FakeBookings.new),
        notificationSummaryProvider.overrideWith(FakeNotif.new),
        riwayatBadgeProvider.overrideWith(FakeRiwayat.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard aman saat pendapatan bulanan null', (tester) async {
    await tampilkanDashboard(tester, 500, summaryNol(bulanan: null));

    expect(tester.takeException(), isNull);
    expect(find.text('Statistik Pendapatan'), findsOneWidget);
    expect(find.text('Rp 0'), findsWidgets);
    expect(find.text('Penyewaan'), findsOneWidget);
    expect(find.text('Penyewaan Lunas'), findsOneWidget);
  });

  testWidgets('dashboard aman saat semua pendapatan 0', (tester) async {
    await tampilkanDashboard(
      tester,
      500,
      summaryNol(
        bulanan: const [
          MonthlyRevenueModel(bulan: '2026-06', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-07', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-08', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-09', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-10', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-11', pendapatan: 0),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Pendapatan bulan November 2026'), findsOneWidget);
    expect(find.text('Sama dengan bulan lalu'), findsOneWidget);
  });

  testWidgets('dashboard aman di layar lebar', (tester) async {
    await tampilkanDashboard(
      tester,
      1200,
      summaryNol(
        bulanan: const [
          MonthlyRevenueModel(bulan: '2026-10', pendapatan: 0),
          MonthlyRevenueModel(bulan: '2026-11', pendapatan: 324000),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Statistik Pendapatan'), findsOneWidget);
  });
}
