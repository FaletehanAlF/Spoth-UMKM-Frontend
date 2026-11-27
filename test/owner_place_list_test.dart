import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/providers/place_provider.dart';
import 'package:spoth_umkm/widgets/owner_place_list.dart';

class FakeMyPlaces extends MyPlacesNotifier {
  FakeMyPlaces(this.items);

  final List<PlaceModel> items;

  @override
  Future<List<PlaceModel>> build() async => items;
}

PlaceModel tempat(String nama, {required bool disewa}) {
  return PlaceModel(
    id: nama,
    hostId: '1',
    namaTempat: nama,
    kategori: 'LAPAK_USAHA',
    deskripsi: 'Lapak usaha contoh untuk pengujian tampilan daftar tempat.',
    alamat: 'Jalan Merdeka nomor 12, Depok',
    kecamatan: 'Beji',
    hargaMingguan: 500000,
    sudahDiSewa: disewa,
  );
}

Future<void> tampilkan(WidgetTester tester, {required double lebar}) async {
  tester.view.physicalSize = Size(lebar, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myPlacesProvider.overrideWith(
          () => FakeMyPlaces([
            tempat('Lapak Pertama', disewa: true),
            tempat('Lapak Kedua', disewa: false),
          ]),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: OwnerPlaceList())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('label hijau tampil di mobile', (tester) async {
    await tampilkan(tester, lebar: 375);

    expect(tester.takeException(), isNull);
    expect(find.text('Lapak Pertama'), findsOneWidget);
    expect(find.text('Sudah disewa'), findsOneWidget);
  });

  testWidgets('web menampilkan dua kartu per baris', (tester) async {
    await tampilkan(tester, lebar: 1440);

    expect(tester.takeException(), isNull);
    expect(find.text('Sudah disewa'), findsOneWidget);

    final pertama = tester.getCenter(find.text('Lapak Pertama'));
    const kedua = 'Lapak Kedua';
    final keduaCenter = tester.getCenter(find.text(kedua));

    expect((pertama.dy - keduaCenter.dy).abs(), lessThan(2));
    expect(keduaCenter.dx, greaterThan(pertama.dx));
  });
}
