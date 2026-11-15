import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_model.dart';
import 'api_service.dart';

/// Provider global untuk [BookingService].
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(apiServiceProvider));
});

/// Akses ke endpoint pemesanan backend SPOTH UMKM (semuanya butuh token):
///
/// - `GET  /bookings`              → riwayat: milik Tenant / pesanan masuk Host
/// - `POST /bookings`              → pemesanan baru (hanya Tenant)
/// - `GET  /bookings/preview-price`→ pratinjau biaya (kunci: `data.pratinjau`)
/// - `POST /bookings/:id/cancel`   → batalkan (hanya Tenant, saat menunggu bayar)
///
/// Validasi jadwal & perhitungan harga dilakukan di backend; frontend
/// tidak pernah menghitung/menganggap pemesanan berhasil sendiri.
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

  /// Riwayat penyewaan. Backend otomatis menyesuaikan isi berdasarkan role:
  /// Tenant melihat penyewaannya sendiri, Host melihat pesanan masuk.
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

  /// Pratinjau biaya sebelum memesan (memeriksa bentrok jadwal juga).
  Future<PricePreviewModel> previewPrice({
    required String token,
    required String placeId,
    required String tanggalMulai,
    required int jumlahDurasi,
  }) async {
    final body = await _apiService.get(
      '/bookings/preview-price${_query({'place_id': placeId, 'tanggal_mulai': tanggalMulai, 'jumlah_durasi': '$jumlahDurasi'})}',
      token: token,
    );

    final data = body['data'] as Map<String, dynamic>?;
    final pratinjau = data?['pratinjau'] as Map<String, dynamic>?;

    if (pratinjau == null) {
      throw const FormatException('Respons pratinjau biaya tidak valid');
    }

    return PricePreviewModel.fromJson(pratinjau);
  }

  /// Tenant membuat pemesanan baru. Backend membuat notifikasi untuk
  /// Tenant dan Host serta menghitung total harga.
  Future<BookingModel> createBooking({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final body = await _apiService.post('/bookings', payload, token: token);
    return _booking(body, 'pemesanan');
  }

  /// Tenant membatalkan pemesanan yang masih menunggu pembayaran.
  Future<BookingModel> cancelBooking({
    required String token,
    required String id,
  }) async {
    final body = await _apiService.post(
      '/bookings/$id/cancel',
      {},
      token: token,
    );
    return _booking(body, 'pembatalan');
  }
}
