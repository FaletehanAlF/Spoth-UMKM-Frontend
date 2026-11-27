import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/booking_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/riwayat_provider.dart';
import 'package:spoth_umkm/screens/booking/riwayat_screen.dart';

class FakeAuthRiwayat extends AuthNotifier {
  FakeAuthRiwayat(this.role);

  final String role;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: role == UserModel.roleHost ? '5' : '3',
      nama: role == UserModel.roleHost ? 'Budi Santoso' : 'Andi Wijaya',
      email: 'uji@spoth.test',
      role: role,
      createdAt: DateTime(2026, 1, 1),
    ),
    token: 'token-uji',
  );
}

class FakeStore implements RiwayatSeenStore {
  @override
  Future<Set<String>> read(String key) async => <String>{};

  @override
  Future<void> write(String key, Set<String> ids) async {}
}

class FakeBookingService extends BookingService {
  FakeBookingService(this.items) : super(ApiService());

  final List<BookingModel> items;

  @override
  Future<List<BookingModel>> listBookings({
    required String token,
    String? status,
    int limit = 50,
  }) async => items;
}

BookingModel bookingContoh() {
  return const BookingModel(
    id: '1',
    kodeBooking: 'SPT-001',
    placeId: '6',
    jenisUsaha: 'Kuliner',
    tanggalMulai: '2026-11-25',
    tanggalSelesai: '2026-12-01',
    jumlahDurasi: 3,
    hargaSatuan: 500000,
    totalHarga: 1502000,
    adminFee: 2000,
    status: 'LUNAS',
    namaTempat: 'Warung Makan Rasa Nusantara',
    namaTenant: 'Andi Wijaya',
    epassTersedia: true,
  );
}

Future<void> tampilkanRiwayat(
  WidgetTester tester, {
  required String role,
  required double lebar,
  required double tinggi,
  required List<BookingModel> items,
}) async {
  tester.view.physicalSize = Size(lebar, tinggi);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => FakeAuthRiwayat(role)),
        riwayatSeenStoreProvider.overrideWithValue(FakeStore()),
        bookingServiceProvider.overrideWithValue(FakeBookingService(items)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const RiwayatScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('penyewa melihat E-Pass dan tanpa error', (tester) async {
    await tampilkanRiwayat(
      tester,
      role: UserModel.roleTenant,
      lebar: 390,
      tinggi: 844,
      items: [bookingContoh()],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Warung Makan Rasa Nusantara'), findsOneWidget);
    expect(find.text('E-Pass'), findsOneWidget);
  });

  testWidgets('pemilik melihat nama penyewa dan E-Pass', (tester) async {
    await tampilkanRiwayat(
      tester,
      role: UserModel.roleHost,
      lebar: 390,
      tinggi: 844,
      items: [bookingContoh()],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Penyewa: Andi Wijaya'), findsOneWidget);
    expect(find.text('E-Pass'), findsOneWidget);
  });

  testWidgets('layar kosong menjelaskan langkah berikutnya', (tester) async {
    await tampilkanRiwayat(
      tester,
      role: UserModel.roleTenant,
      lebar: 390,
      tinggi: 844,
      items: const [],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
  });

  testWidgets('riwayat web menampilkan dua kartu per baris', (tester) async {
    final pertama = bookingContoh();
    final kedua = BookingModel(
      id: '2',
      kodeBooking: 'SPT-002',
      placeId: '7',
      jenisUsaha: 'Kuliner',
      tanggalMulai: '2026-11-25',
      tanggalSelesai: '2026-12-01',
      jumlahDurasi: 1,
      hargaSatuan: 500000,
      totalHarga: 500000,
      status: 'LUNAS',
      namaTempat: 'Ruang Usaha Kedua',
      epassTersedia: true,
    );

    await tampilkanRiwayat(
      tester,
      role: UserModel.roleTenant,
      lebar: 1200,
      tinggi: 900,
      items: [pertama, kedua],
    );

    expect(tester.takeException(), isNull);
    final yPertama = tester.getCenter(
      find.text('Warung Makan Rasa Nusantara'),
    ).dy;
    final yKedua = tester.getCenter(find.text('Ruang Usaha Kedua')).dy;

    expect((yPertama - yKedua).abs(), lessThan(2));
  });
}
