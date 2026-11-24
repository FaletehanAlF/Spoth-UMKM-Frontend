import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/place_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/screens/place/place_detail_screen.dart';

class FakeAuthTenant extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: '3',
      nama: 'Andi Wijaya',
      email: 'tenant@spoth.test',
      role: 'TENANT',
      createdAt: DateTime(2026, 1, 1),
    ),
    token: 'token-uji',
  );
}

class FakePlaceService extends PlaceService {
  FakePlaceService(this.place) : super(ApiService());

  final PlaceModel place;

  @override
  Future<PlaceModel> getPlaceDetail({
    required String id,
    String? token,
  }) async => place;
}

PlaceModel tempatContoh() {
  return PlaceModel(
    id: '6',
    hostId: '5',
    namaTempat: 'Warung Makan Rasa Nusantara',
    kategori: 'LAPAK_USAHA',
    deskripsi:
        'Warung makan yang menyediakan berbagai hidangan khas Nusantara '
        'dengan harga terjangkau dan bahan berkualitas.',
    alamat: 'Jl. H. Amat No. 25, Kukusan, Beji, Depok',
    kecamatan: 'Beji',
    harga: 500000,
    tipeDurasi: 'MINGGUAN',
    namaHost: 'Budi Santoso',
    updatedAt: DateTime(2026, 11, 23),
    tanggalMulaiTersedia: DateTime(2026, 11, 24),
    tanggalSelesaiTersedia: DateTime(2026, 12, 1),
    jadwalTerpakai: const [
      BookedRange(
        tanggalMulai: '2026-11-25',
        tanggalSelesai: '2026-11-27',
        status: 'LUNAS',
      ),
    ],
  );
}

Future<void> tampilkanDetail(
  WidgetTester tester, {
  required double lebar,
  required double tinggi,
}) async {
  tester.view.physicalSize = Size(lebar, tinggi);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthTenant.new),
        placeServiceProvider.overrideWithValue(FakePlaceService(tempatContoh())),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PlaceDetailScreen(placeId: '6'),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('detail tempat tanpa overflow di ponsel', (tester) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(tester.takeException(), isNull);
    expect(find.text('Warung Makan Rasa Nusantara'), findsOneWidget);
    expect(find.text('Deskripsi'), findsOneWidget);
    expect(find.text('Periode Ketersediaan'), findsOneWidget);
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
  });

  testWidgets('detail tempat tanpa overflow di ponsel sempit', (tester) async {
    await tampilkanDetail(tester, lebar: 320, tinggi: 800);

    expect(tester.takeException(), isNull);
    expect(find.text('Deskripsi'), findsOneWidget);
  });

  testWidgets('detail tempat tanpa overflow di web lebar', (tester) async {
    await tampilkanDetail(tester, lebar: 1440, tinggi: 900);

    expect(tester.takeException(), isNull);
    expect(find.text('Deskripsi'), findsOneWidget);
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
  });

  testWidgets('bagian kosong tidak menampilkan judulnya', (tester) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(find.text('Aturan'), findsNothing);
    expect(find.text('Aturan ketersediaan'), findsNothing);
  });
}
