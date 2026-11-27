import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/category_model.dart';
import 'package:spoth_umkm/screens/place/place_form/place_fields.dart';
import 'package:spoth_umkm/widgets/category_picker.dart';

Widget _bungkus(Widget child, double lebar) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: lebar, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('field informasi aman di lebar ponsel sempit', (tester) async {
    await tester.pumpWidget(
      _bungkus(
        InfoFields(
          namaController: TextEditingController(),
          alamatController: TextEditingController(),
          deskripsiController: TextEditingController(),
          kategoriLainController: TextEditingController(),
          kategori: 'TERAS_KOMERSIAL',
          onKategoriChanged: (_) {},
          kecamatan: 'Pancoran Mas',
          onKecamatanChanged: (_) {},
          categories: const [
            CategoryModel(id: '1', nama: 'TERAS_KOMERSIAL', isPreset: true),
          ],
          categoriesLoading: false,
          categoriesError: null,
          onRetryCategories: () {},
          enabled: true,
        ),
        320,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Nama Tempat'), findsOneWidget);
    expect(find.text('Deskripsi'), findsOneWidget);
  });

  testWidgets('harga paket memakai label per minggu dan per bulan', (tester) async {
    await tester.pumpWidget(
      _bungkus(
        PriceDurationFields(
          paketMingguan: true,
          paketBulanan: true,
          hargaMingguanController: TextEditingController(),
          hargaBulananController: TextEditingController(),
          onPaketMingguanChanged: (_) {},
          onPaketBulananChanged: (_) {},
          enabled: true,
        ),
        320,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    expect(find.text('Harga per minggu'), findsOneWidget);
    expect(find.text('Harga per bulan'), findsOneWidget);
    expect(find.textContaining('1 minggu ='), findsNothing);
    expect(find.textContaining('1 bulan ='), findsNothing);
  });

  testWidgets('pilihan kategori tidak memakai ikon pada chip', (tester) async {
    await tester.pumpWidget(
      _bungkus(
        CategoryPicker(
          categories: const [
            CategoryModel(id: '1', nama: 'TERAS_KOMERSIAL', isPreset: true),
          ],
          selected: 'TERAS_KOMERSIAL',
          onChanged: (_) {},
        ),
        320,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Teras Komersial'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
  });
}
