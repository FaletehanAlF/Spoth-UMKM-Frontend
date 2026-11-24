import 'place_model.dart';

class PlaceAvailabilityModel {
  const PlaceAvailabilityModel({
    required this.tersedia,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahDurasi,
    this.konflik = const [],
  });

  final bool tersedia;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahDurasi;
  final List<BookedRange> konflik;

  int get jumlahKonflik => konflik.length;

  factory PlaceAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final nilai = json['tersedia'];
    if (nilai is! bool) {
      throw const FormatException(
        'Respons ketersediaan tempat tidak valid: nilai tersedia harus '
        'berupa boolean.',
      );
    }

    return PlaceAvailabilityModel(
      tersedia: nilai,
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      jumlahDurasi: json['jumlah_durasi'] is num
          ? (json['jumlah_durasi'] as num).toInt()
          : 0,
      konflik: (json['konflik'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookedRange.fromJson)
          .toList(),
    );
  }
}
