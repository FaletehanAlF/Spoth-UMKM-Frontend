import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_model.dart';
import 'api_service.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(apiServiceProvider));
});

class BookingService {
  BookingService(this._apiService);

  final ApiService _apiService;

  String _query(Map<String, String?> params) {
    final entries = <String, String>{};
    params.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        entries[key] = value;
      }
    });

    final query = Uri(queryParameters: entries).query;
    return query.isEmpty ? '' : '?$query';
  }

  BookingModel _booking(Map<String, dynamic> body, String label) {
    final data = body['data'] as Map<String, dynamic>?;
    final booking = data?['booking'] as Map<String, dynamic>?;

    if (booking == null) {
      throw FormatException('Respons $label pemesanan tidak valid');
    }

    return BookingModel.fromJson(booking);
  }

  Future<List<BookingModel>> listBookings({
    required String token,
    String? status,
    int limit = 50,
  }) async {
    final body = await _apiService.get(
      '/bookings${_query({'status': status, 'page': '1', 'limit': '$limit'})}',
      token: token,
    );

    final data = body['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>?;

    if (items == null) {
      throw const FormatException('Respons riwayat pemesanan tidak valid');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(BookingModel.fromJson)
        .toList();
  }

  Future<PricePreviewModel> previewPrice({
    required String token,
    required String placeId,
    required String tanggalMulai,
    required String tipeDurasi,
    required int jumlahDurasi,
  }) async {
    final body = await _apiService.get(
      '/bookings/preview-price${_query({'place_id': placeId, 'tanggal_mulai': tanggalMulai, 'tipe_durasi': tipeDurasi, 'jumlah_durasi': '$jumlahDurasi'})}',
      token: token,
    );

    final data = body['data'] as Map<String, dynamic>?;
    final pratinjau = data?['pratinjau'] as Map<String, dynamic>?;

    if (pratinjau == null) {
      throw const FormatException('Respons pratinjau biaya tidak valid');
    }

    return PricePreviewModel.fromJson(pratinjau);
  }

  Future<BookingModel> createBooking({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.post('/bookings', payload, token: token);
    return _booking(body, 'pemesanan');
  }

  Future<BookingModel> getBooking({
    required String token,
    required String id,
  }) async {
    final body = await _apiService.get('/bookings/$id', token: token);
    return _booking(body, 'detail');
  }
}
