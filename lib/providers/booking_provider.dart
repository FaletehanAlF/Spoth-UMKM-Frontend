import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/booking_service.dart';
import '../models/booking_model.dart';
import 'auth_provider.dart';

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final bookingsProvider =
    AsyncNotifierProvider<BookingsNotifier, List<BookingModel>>(
      BookingsNotifier.new,
    );

final bookingBadgeProvider = Provider<int>((ref) {
  final bookings = ref.watch(bookingsProvider).value ?? const <BookingModel>[];
  return bookings
      .where((booking) => booking.status == 'MENUNGGU_PEMBAYARAN')
      .length;
});
