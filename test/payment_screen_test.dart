import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoth_umkm/core/services/api_service.dart';
import 'package:spoth_umkm/core/services/booking_service.dart';
import 'package:spoth_umkm/core/services/payment_service.dart';
import 'package:spoth_umkm/core/theme/app_theme.dart';
import 'package:spoth_umkm/models/booking_model.dart';
import 'package:spoth_umkm/models/payment_model.dart';
import 'package:spoth_umkm/models/user_model.dart';
import 'package:spoth_umkm/providers/auth_provider.dart';
import 'package:spoth_umkm/providers/booking_provider.dart';
import 'package:spoth_umkm/providers/riwayat_provider.dart';
import 'package:spoth_umkm/screens/booking/payment_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: '3',
      nama: 'Andi Wijaya',
      email: 'uji@spoth.test',
      role: UserModel.roleTenant,
      createdAt: DateTime(2026, 1, 1),
    ),
    token: 'token-uji',
  );
}

class _Booking extends BookingService {
  _Booking() : super(ApiService());

  @override
  Future<BookingModel> getBooking({
    required String token,
    required String id,
  }) async {
    return BookingModel(
      id: id,
      placeId: '6',
      jenisUsaha: 'Kuliner',
      tanggalMulai: '2026-11-28',
      tanggalSelesai: '2026-12-05',
      jumlahDurasi: 1,
      hargaSatuan: 500000,
      totalHarga: 502000,
      adminFee: 2000,
      status: 'MENUNGGU_PEMBAYARAN',
      namaTempat: 'Warung Makan Rasa Nusantara',
    );
  }
}

class _Payment extends PaymentService {
  _Payment(this.status) : super(ApiService());

  final String status;

  @override
  Future<PaymentModel?> getPayment({
    required String token,
    required String bookingId,
  }) async {    return PaymentModel(
      metode: 'MIDTRANS',
      status: status,
      kodeBooking: null,
      redirectUrl: 'https://app.sandbox.midtrans.com/snap/v4/redirection/uji',
    );
  }
}

class _Bookings extends BookingsNotifier {
  @override
  Future<List<BookingModel>> build() async => const [];
}

class _Riwayat extends RiwayatBadgeNotifier {
  @override
  Future<int> build() async => 0;
}

Future<void> tampilkanPembayaran(
  WidgetTester tester, {
  required double lebar,
  required String statusPembayaran,
}) async {
  tester.view.physicalSize = Size(lebar, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        bookingServiceProvider.overrideWithValue(_Booking()),
        paymentServiceProvider.overrideWithValue(_Payment(statusPembayaran)),
        bookingsProvider.overrideWith(_Bookings.new),
        riwayatBadgeProvider.overrideWith(_Riwayat.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PaymentScreen(bookingId: '42'),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pembayaran mobile menampilkan tombol Midtrans tanpa overflow', (
    tester,
  ) async {
    await tampilkanPembayaran(tester, lebar: 375, statusPembayaran: 'PENDING');

    expect(tester.takeException(), isNull);
    expect(find.text('Bayar dengan Midtrans'), findsNothing);
    expect(find.text('Buka Halaman Pembayaran'), findsOneWidget);
    expect(find.text('Cek Status Pembayaran'), findsOneWidget);
    expect(find.text('Buat Ulang Pembayaran'), findsOneWidget);
    expect(find.text('Rp 502.000'), findsWidgets);
  });

  testWidgets('pembayaran web dua kolom tidak overflow', (tester) async {
    await tampilkanPembayaran(tester, lebar: 1440, statusPembayaran: 'PENDING');

    expect(tester.takeException(), isNull);
    expect(find.text('Metode Pembayaran'), findsOneWidget);
    expect(find.text('Buka Halaman Pembayaran'), findsOneWidget);
  });

  testWidgets('pembayaran tanpa transaksi menawarkan tombol Bayar', (
    tester,
  ) async {
    await tampilkanPembayaran(
      tester,
      lebar: 320,
      statusPembayaran: 'DIBATALKAN',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Bayar dengan Midtrans'), findsOneWidget);
  });
}
