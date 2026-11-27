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
import 'package:spoth_umkm/screens/home/tenant_home_screen.dart';

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

class FakeTenantPlaces extends TenantPlacesNotifier {
  FakeTenantPlaces(this.items);

  final List<PlaceModel> items;

  @override
  Future<List<PlaceModel>> build() async => items;
}

class FakeBookingsAktif extends BookingsNotifier {
  FakeBookingsAktif(this.items);

  final List<BookingModel> items;

  @override
  Future<List<BookingModel>> build() async => items;
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

PlaceModel tempatContoh(String id) {
  return PlaceModel(
    id: id,
    hostId: '1',
    namaTempat: 'Teras Ruko Merdeka Nomor $id',
    kategori: 'TERAS_KOMERSIAL',
    deskripsi: 'Teras ruko di pinggir jalan raya.',
    alamat: 'Jl. Merdeka No. 12',
    kecamatan: 'Pancoran Mas',
    hargaMingguan: 150000,
    hargaBulanan: 450000,
  );
}

BookingModel bookingContoh({required String status, required String selesai}) {
  return BookingModel(
    id: '1',
    kodeBooking: status == 'LUNAS' ? 'SPOTH-20261101-0001' : null,
    placeId: '1',
    jenisUsaha: 'Kedai kopi',
    tanggalMulai: '2026-11-20',
    tanggalSelesai: selesai,
    jumlahDurasi: 3,
    hargaSatuan: 150000,
    totalHarga: 452000,
    adminFee: 2000,
    status: status,
    namaTempat: 'Teras Ruko Merdeka',
  );
}

Future<void> tampilkanBeranda(
  WidgetTester tester, {
  required double lebar,
  List<PlaceModel>? places,
  List<BookingModel> bookings = const [],
}) async {
  tester.view.physicalSize = Size(lebar, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthTenant.new),
        tenantPlacesProvider.overrideWith(
          () => FakeTenantPlaces(places ?? [tempatContoh('1')]),
        ),
        bookingsProvider.overrideWith(() => FakeBookingsAktif(bookings)),
        notificationSummaryProvider.overrideWith(FakeNotif.new),
        riwayatBadgeProvider.overrideWith(FakeRiwayat.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const TenantHomeScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('beranda penyewa tanpa overflow di ponsel', (tester) async {
    await tampilkanBeranda(tester, lebar: 375);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ruang usaha'), findsNothing);
    expect(find.text('Tempat terbaru'), findsOneWidget);
    expect(find.byKey(const ValueKey('tempat-terbaru')), findsOneWidget);
    expect(find.text('Tempat untukmu'), findsNothing);
  });

  testWidgets('tempat paling baru tampil besar dan sisanya di bawah', (
    tester,
  ) async {
    await tampilkanBeranda(
      tester,
      lebar: 375,
      places: [
        tempatContoh('1'),
        tempatContoh('2'),
        tempatContoh('3'),
        tempatContoh('4'),
        tempatContoh('5'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('tempat-terbaru')), findsOneWidget);
    expect(find.text('Teras Ruko Merdeka Nomor 1'), findsOneWidget);
    expect(find.text('Teras Ruko Merdeka Nomor 4'), findsWidgets);
    expect(find.text('Teras Ruko Merdeka Nomor 5'), findsOneWidget);
    expect(find.text('Tempat untukmu'), findsOneWidget);
  });

  testWidgets('hanya ada satu tautan Lihat semua di ponsel', (tester) async {
    await tampilkanBeranda(
      tester,
      lebar: 375,
      places: [tempatContoh('1'), tempatContoh('2')],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lihat semua'), findsOneWidget);
  });

  testWidgets('hanya ada satu tautan Lihat semua di web', (tester) async {
    await tampilkanBeranda(
      tester,
      lebar: 1440,
      places: [tempatContoh('1'), tempatContoh('2'), tempatContoh('3')],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lihat semua'), findsOneWidget);
  });

  testWidgets('beranda tidak memuat filter kategori', (tester) async {
    await tampilkanBeranda(tester, lebar: 320);

    expect(tester.takeException(), isNull);
    expect(find.text('Lapak Usaha'), findsNothing);
    expect(find.text('Teras Komersial'), findsNothing);
    expect(find.text('Booth Event'), findsNothing);
    expect(find.text('Semua'), findsNothing);
    expect(find.byIcon(Icons.apps), findsNothing);
  });

  testWidgets('Lihat semua berada di sebelah kanan kartu terbaru', (
    tester,
  ) async {
    await tampilkanBeranda(
      tester,
      lebar: 375,
      places: [tempatContoh('1'), tempatContoh('2')],
    );

    expect(tester.takeException(), isNull);
    final kartu = tester.getRect(find.byKey(const ValueKey('tempat-terbaru')));
    final tautan = tester.getRect(find.text('Lihat semua'));
    expect(tautan.right, greaterThan(kartu.center.dx));
    expect(kartu.bottom, lessThan(tautan.top));
  });

  testWidgets('beranda penyewa tanpa overflow di web lebar', (tester) async {
    await tampilkanBeranda(
      tester,
      lebar: 1440,
      places: [
        tempatContoh('1'),
        tempatContoh('2'),
        tempatContoh('3'),
        tempatContoh('4'),
        tempatContoh('5'),
        tempatContoh('6'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Tempat terbaru'), findsOneWidget);
    expect(find.text('Tempat untukmu'), findsOneWidget);
    expect(find.text('Teras Ruko Merdeka Nomor 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('baris-sorotan')), findsNWidgets(4));
  });

  testWidgets('beranda web dengan sidebar tetap dua kolom', (tester) async {
    await tampilkanBeranda(
      tester,
      lebar: 1024,
      places: [
        tempatContoh('1'),
        tempatContoh('2'),
        tempatContoh('3'),
        tempatContoh('4'),
        tempatContoh('5'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('baris-sorotan')), findsNWidgets(4));
  });

  testWidgets('penyewaan berjalan tidak lagi tampil di beranda', (
    tester,
  ) async {
    final selesai = DateTime.now().add(const Duration(days: 8));

    await tampilkanBeranda(
      tester,
      lebar: 375,
      bookings: [
        bookingContoh(
          status: 'MENUNGGU_PEMBAYARAN',
          selesai: selesai.toIso8601String().split('T').first,
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Penyewaan berjalan'), findsNothing);
    expect(find.byKey(const ValueKey('tempat-terbaru')), findsOneWidget);
  });

  testWidgets('kondisi kosong menjelaskan langkah berikutnya', (tester) async {
    await tampilkanBeranda(tester, lebar: 375, places: const []);

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada tempat tersedia'), findsOneWidget);
  });

  testWidgets('menghapus teks pencarian mengembalikan semua tempat', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthTenant.new),
        tenantPlacesProvider.overrideWith(
          () => FakeTenantPlaces([tempatContoh('1')]),
        ),
        bookingsProvider.overrideWith(() => FakeBookingsAktif(const [])),
        notificationSummaryProvider.overrideWith(FakeNotif.new),
        riwayatBadgeProvider.overrideWith(FakeRiwayat.new),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(375, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TenantHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, 'tidak-ada');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(container.read(tenantSearchProvider).keyword, 'tidak-ada');

    await tester.enterText(field, '');
    await tester.pumpAndSettle();

    expect(container.read(tenantSearchProvider).keyword, isEmpty);
  });
}
