class BookingModel {
  const BookingModel({
    required this.id,
    this.kodeBooking,
    required this.placeId,
    this.tenantId = '',
    required this.jenisUsaha,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahDurasi,
    required this.hargaSatuan,
    required this.totalHarga,
    required this.status,
    this.createdAt,
    this.namaTempat,
    this.kota,
    this.namaTenant,
    this.namaHost,
    this.foto = const [],
  });

  final String id;
  final String? kodeBooking;
  final String placeId;
  final String tenantId;
  final String jenisUsaha;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahDurasi;
  final double hargaSatuan;
  final double totalHarga;
  final String status;
  final DateTime? createdAt;
  final String? namaTempat;
  final String? kota;
  final String? namaTenant;
  final String? namaHost;
  final List<String> foto;

  String get statusLabel {
    switch (status) {
      case 'MENUNGGU_PEMBAYARAN':
        return 'Menunggu Bayar';
      case 'LUNAS':
        return 'Lunas';
      case 'DIBATALKAN':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  bool get bisaDibatalkan => status == 'MENUNGGU_PEMBAYARAN';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      kodeBooking: json['kode_booking'] as String?,
      placeId: json['place_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      jenisUsaha: json['jenis_usaha'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      jumlahDurasi: json['jumlah_durasi'] is num
          ? (json['jumlah_durasi'] as num).toInt()
          : 0,
      hargaSatuan: _toDouble(json['harga_satuan']),
      totalHarga: _toDouble(json['total_harga']),
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      namaTempat: json['nama_tempat'] as String?,
      kota: json['kota'] as String?,
      namaTenant: json['nama_tenant'] as String?,
      namaHost: json['nama_host'] as String?,
      foto:
          (json['foto'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class PricePreviewModel {
  const PricePreviewModel({
    required this.namaTempat,
    required this.tanggalSelesai,
    required this.tipeDurasi,
    required this.hargaSatuan,
    required this.totalHarga,
    required this.tersedia,
    required this.jumlahKonflik,
  });

  final String namaTempat;
  final String tanggalSelesai;
  final String tipeDurasi;
  final double hargaSatuan;
  final double totalHarga;
  final bool tersedia;
  final int jumlahKonflik;

  factory PricePreviewModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) => value is num ? value.toDouble() : 0;

    return PricePreviewModel(
      namaTempat: json['nama_tempat'] as String? ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      hargaSatuan: toDouble(json['harga_satuan']),
      totalHarga: toDouble(json['total_harga']),
      tersedia: json['tersedia'] as bool? ?? false,
      jumlahKonflik: (json['konflik'] as List<dynamic>?)?.length ?? 0,
    );
  }
}
