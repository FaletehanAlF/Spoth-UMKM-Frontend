import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/widgets/dashboard/revenue_chart.dart';

Future<void> tampilkanGrafik(
  WidgetTester tester, {
  required List<MonthlyRevenueModel> data,
  double lebar = 390,
}) async {
  tester.view.physicalSize = Size(lebar, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: RevenueChart(data: data),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  const data = [
    MonthlyRevenueModel(bulan: '2026-06', pendapatan: 0),
    MonthlyRevenueModel(bulan: '2026-07', pendapatan: 350000),
    MonthlyRevenueModel(bulan: '2026-08', pendapatan: 0),
    MonthlyRevenueModel(bulan: '2026-09', pendapatan: 900000),
    MonthlyRevenueModel(bulan: '2026-10', pendapatan: 1200000),
    MonthlyRevenueModel(bulan: '2026-11', pendapatan: 1800000),
  ];

  testWidgets('grafik tampil tanpa overflow di ponsel', (tester) async {
    await tampilkanGrafik(tester, data: data);

    expect(tester.takeException(), isNull);
    expect(find.byType(RevenueChart), findsOneWidget);
    expect(find.text('Ketuk titik untuk melihat nilai bulan'), findsOneWidget);
  });

  testWidgets('mengetuk titik menampilkan nilai bulannya', (tester) async {
    await tampilkanGrafik(tester, data: data);
    await _ketukTitik(tester, 5);

    expect(find.text('November 2026 · Rp 1.800.000'), findsOneWidget);
  });

  testWidgets('mengetuk titik lain memakai nilai bulan itu', (tester) async {
    await tampilkanGrafik(tester, data: data);
    await _ketukTitik(tester, 3);

    expect(find.text('September 2026 · Rp 900.000'), findsOneWidget);
  });

  testWidgets('grafik kosong memberi pesan yang jelas', (tester) async {
    await tampilkanGrafik(tester, data: const []);

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada pendapatan pada periode ini'), findsOneWidget);
  });
}

Future<void> _ketukTitik(WidgetTester tester, int index) async {
  final area = tester.getRect(find.byKey(const ValueKey('grafik-pendapatan')));
  final langkah = (area.width - 2) / 5;
  final x = (area.left + 1 + langkah * index).clamp(
    area.left + 1,
    area.right - 1,
  );

  await tester.tapAt(Offset(x, area.center.dy));
  await tester.pumpAndSettle();
}
