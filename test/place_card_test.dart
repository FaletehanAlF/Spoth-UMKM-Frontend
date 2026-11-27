import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/widgets/place_grid.dart';

PlaceModel kartuContoh({required bool sudahDisewa}) {
  return PlaceModel(
    id: '1',
    hostId: '1',
    namaTempat: 'Teras Ruko Merdeka',
    kategori: 'TERAS_KOMERSIAL',
    deskripsi: 'Teras ruko di pinggir jalan raya.',
    alamat: 'Jl. Merdeka No. 12',
    kecamatan: 'Pancoran Mas',
    hargaMingguan: 150000,
    hargaBulanan: 450000,
    sudahDiSewa: sudahDisewa,
  );
}

Future<void> tampilkanGrid(
  WidgetTester tester, {
  required double lebar,
  required bool sudahDisewa,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: lebar,
            child: PlaceGrid(places: [kartuContoh(sudahDisewa: sudahDisewa)]),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kartu tempat aman di lebar ponsel sempit', (tester) async {
    await tampilkanGrid(tester, lebar: 174, sudahDisewa: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Sedang disewa'), findsOneWidget);
    expect(find.text('Teras Komersial'), findsOneWidget);
  });

  testWidgets('kartu tempat aman di lebar kartu menengah', (tester) async {
    await tampilkanGrid(tester, lebar: 260, sudahDisewa: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Sedang disewa'), findsOneWidget);
  });

  testWidgets('kartu tempat aman di lebar lebar', (tester) async {
    await tampilkanGrid(tester, lebar: 1100, sudahDisewa: true);

    expect(tester.takeException(), isNull);
  });

  testWidgets('lencana tidak muncul bila tempat kosong', (tester) async {
    await tampilkanGrid(tester, lebar: 200, sudahDisewa: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Sedang disewa'), findsNothing);
  });
}
