import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/place_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/place_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/booking_provider.dart';
import 'package:spoth_umkm/models/booking_model.dart';
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

class FakeAuthHost extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: '5',
      nama: 'Budi Santoso',
      email: 'host@spoth.test',
      role: 'HOST',
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

class FakeBookings extends BookingsNotifier {
  FakeBookings(this.items);

  final List<BookingModel> items;

  @override
  Future<List<BookingModel>> build() async => items;
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
    hargaMingguan: 500000,
    hargaBulanan: null,
    namaHost: 'Budi Santoso',
    fotoHost: 'http://127.0.0.1/foto-host.png',
    updatedAt: DateTime(2026, 11, 23),
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
  List<BookingModel> bookings = const [],
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
        bookingsProvider.overrideWith(() => FakeBookings(bookings)),
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
    expect(find.text('Periode Ketersediaan'), findsNothing);
    expect(find.text('Jadwal Sudah Dipesan'), findsOneWidget);
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

  testWidgets('tombol sewa hilang bila penyewa sudah menyewa tempat ini', (
    tester,
  ) async {
    final selesai = DateTime.now().add(const Duration(days: 10));

    await tampilkanDetail(
      tester,
      lebar: 375,
      tinggi: 1000,
      bookings: [
        BookingModel(
          id: '1',
          placeId: '6',
          jenisUsaha: 'Warung makan',
          tanggalMulai: '2026-11-24',
          tanggalSelesai: selesai.toIso8601String().split('T').first,
          jumlahDurasi: 1,
          hargaSatuan: 500000,
          totalHarga: 502000,
          status: 'LUNAS',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sewa Tempat Ini'), findsNothing);
    expect(find.textContaining('sudah menyewa tempat ini'), findsOneWidget);
  });

  testWidgets('harga tampil sekali dekat judul dan tidak di bar bawah', (
    tester,
  ) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(tester.takeException(), isNull);
    expect(find.text('Rp 500.000 /minggu'), findsOneWidget);
    expect(find.text('Harga sewa'), findsNothing);
  });

  testWidgets('detail tidak menampilkan kategori dan nama pemilik', (
    tester,
  ) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(tester.takeException(), isNull);
    expect(find.text('Lapak Usaha'), findsNothing);
    expect(find.text('Budi Santoso'), findsNothing);
    expect(find.text('Pemilik tempat'), findsOneWidget);
  });

  testWidgets('foto utama ponsel penuh lebar dan lembar info menutupnya', (
    tester,
  ) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(
      tester.getSize(find.byKey(const ValueKey('foto-utama-ponsel'))).width,
      375,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail memakai baris pemilik bukan rating bintang', (tester) async {
    await tampilkanDetail(tester, lebar: 375, tinggi: 1000);

    expect(find.text('Pemilik tempat'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.star_rate), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pilihan paket mengubah harga yang tampil', (tester) async {
    final contoh = tempatContoh();
    final duaPaket = PlaceModel(
      id: contoh.id,
      hostId: contoh.hostId,
      namaTempat: contoh.namaTempat,
      kategori: contoh.kategori,
      deskripsi: contoh.deskripsi,
      alamat: contoh.alamat,
      kecamatan: contoh.kecamatan,
      hargaMingguan: contoh.hargaMingguan,
      hargaBulanan: 1800000,
      namaHost: contoh.namaHost,
      updatedAt: contoh.updatedAt,
      jadwalTerpakai: contoh.jadwalTerpakai,
    );

    tester.view.physicalSize = const Size(375, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(FakeAuthTenant.new),
          placeServiceProvider.overrideWithValue(FakePlaceService(duaPaket)),
          bookingsProvider.overrideWith(() => FakeBookings(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceDetailScreen(placeId: '6'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulanan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rp 1.800.000 /bulan'), findsOneWidget);
    expect(find.text('Rp 500.000 /minggu'), findsNothing);
  });

  testWidgets('pemilik tidak melihat tombol sewa di detail tempatnya', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthHost()),
          placeServiceProvider.overrideWithValue(FakePlaceService(tempatContoh())),
          bookingsProvider.overrideWith(() => FakeBookings(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceDetailScreen(placeId: '6'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sewa Tempat Ini'), findsNothing);
  });

  testWidgets('tombol sewa tetap ada bila pesanan sudah lewat', (tester) async {
    await tampilkanDetail(
      tester,
      lebar: 375,
      tinggi: 1000,
      bookings: [
        BookingModel(
          id: '2',
          placeId: '6',
          jenisUsaha: 'Warung makan',
          tanggalMulai: '2020-01-01',
          tanggalSelesai: '2020-01-05',
          jumlahDurasi: 1,
          hargaSatuan: 500000,
          totalHarga: 502000,
          status: 'LUNAS',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sewa Tempat Ini'), findsOneWidget);
  });
}
