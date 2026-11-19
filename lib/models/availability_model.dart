import 'place_model.dart';

class AvailabilityRuleModel {
  const AvailabilityRuleModel({
    required this.id,
    required this.placeId,
    required this.tipeAturan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.hari,
    this.bulan,
    required this.tersedia,
    this.createdAt,
    this.updatedAt,
  });

  static const Map<String, String> tipeLabels = {
    'TANGGAL': 'Tanggal',
    'HARI': 'Hari',
    'BULAN': 'Bulan',
  };

  static const Map<int, String> hariLabels = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    0: 'Minggu',
  };

  static const Map<int, String> bulanLabels = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  final String id;
  final String placeId;
  final String tipeAturan;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int? hari;
  final int? bulan;
  final bool tersedia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get tipeLabel => tipeLabels[tipeAturan] ?? tipeAturan;

  String get sasaranLabel {
    switch (tipeAturan) {
      case 'HARI':
        return 'Setiap hari ${hariLabels[hari] ?? '-'}';
      case 'BULAN':
        return 'Setiap bulan ${bulanLabels[bulan] ?? '-'}';
      case 'TANGGAL':
        return 'Semua tanggal dalam rentang';
      default:
        return 'Aturan ketersediaan';
    }
  }

  String get statusLabel => tersedia ? 'Tersedia' : 'Tidak tersedia';

  bool get memblokir => !tersedia;

  Map<String, dynamic> toPayload() {
    return {
      'tipe_aturan': tipeAturan,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'hari': tipeAturan == 'HARI' ? hari : null,
      'bulan': tipeAturan == 'BULAN' ? bulan : null,
      'tersedia': tersedia,
    };
  }

  factory AvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleModel(
      id: json['id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      tipeAturan: json['tipe_aturan'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      hari: json['hari'] is num ? (json['hari'] as num).toInt() : null,
      bulan: json['bulan'] is num ? (json['bulan'] as num).toInt() : null,
      tersedia: _bacaTersedia(json, 'aturan ketersediaan'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

bool _bacaTersedia(Map<String, dynamic> json, String konteks) {
  final nilai = json['tersedia'];

  if (nilai is bool) {
    return nilai;
  }

  throw FormatException(
    'Respons $konteks tidak valid: nilai tersedia harus berupa boolean.',
  );
}

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
    return PlaceAvailabilityModel(
      tersedia: _bacaTersedia(json, 'ketersediaan tempat'),
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
