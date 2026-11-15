import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/booking_service.dart';
import '../models/booking_model.dart';
import 'auth_provider.dart';

/// Riwayat pemesanan (`GET /bookings`).
///
/// Backend menyesuaikan isi berdasarkan role: Penyewa melihat penyewaannya
/// sendiri, Pemilik melihat pesanan masuk untuk tempat miliknya.
class BookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  Future<List<BookingModel>> _fetch() async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return const <BookingModel>[];
    }

    return ref.read(bookingServiceProvider).listBookings(token: token);
  }

  @override
  Future<List<BookingModel>> build() async {
    ref.watch(authNotifierProvider.select((state) => state.token));
    return _fetch();
  }

  /// Memuat ulang riwayat pemesanan.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Penyewa membatalkan pemesanan (hanya status menunggu pembayaran;
  /// validasi kepemilikan & status dilakukan di backend).
  Future<void> cancel(String id) async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));

    if (token == null) {
      return;
    }

    await ref.read(bookingServiceProvider).cancelBooking(token: token, id: id);
    await refresh();
  }
}

/// Provider riwayat pemesanan (dipakai tab Booking untuk kedua role).
final bookingsProvider =
    AsyncNotifierProvider<BookingsNotifier, List<BookingModel>>(
      BookingsNotifier.new,
    );
