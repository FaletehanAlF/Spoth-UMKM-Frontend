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
    this.tipeDurasi = 'MINGGUAN',
    required this.hargaSatuan,
    required this.totalHarga,
    this.adminFee = 0,
    this.komisiPlatform = 0,
    this.pendapatanHost = 0,
    required this.status,
    this.createdAt,
    this.namaTempat,
    this.kecamatan,
    this.namaTenant,
    this.namaHost,
    this.foto = const [],
    this.statusLabel,
    this.epassTersedia = false,
  });

  final String id;
  final String? kodeBooking;
  final String placeId;
  final String tenantId;
  final String jenisUsaha;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahDurasi;

  /// Satuan paket yang dipilih penyewa ("MINGGUAN" atau "BULANAN").
  final String tipeDurasi;
  final double hargaSatuan;
  final double totalHarga;
  final double adminFee;
  /// Biaya admin platform yang masuk ke platform.
  final double komisiPlatform;
  /// Pendapatan host (harga sewa) sebelum dipakai.
  final double pendapatanHost;
  final String status;
  final DateTime? createdAt;
  final String? namaTempat;
  final String? kecamatan;
  final String? namaTenant;
  final String? namaHost;
  final List<String> foto;
  /// Label status siap tampil dari server (contoh: "Berhasil Disewa").
  /// Jika server tidak mengirimnya, fallback ke label lokal.
  final String? statusLabel;
  /// True bila E-Pass sudah bisa dibuka (pemesanan lunas).
  final bool epassTersedia;

  String get displayStatusLabel {
    if (statusLabel != null && statusLabel!.trim().isNotEmpty) {
      return statusLabel!;
    }
    return statusLabelLokal;
  }

  String get statusLabelLokal {
    switch (status) {
      case 'MENUNGGU_PEMBAYARAN':
        return 'Menunggu Bayar';
      case 'LUNAS':
        return 'Berhasil Disewa';
      case 'DIBATALKAN':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String? get firstFoto => foto.isNotEmpty ? foto.first : null;

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
      tipeDurasi: json['tipe_durasi'] as String? ?? 'MINGGUAN',
      hargaSatuan: _toDouble(json['harga_satuan']),
      totalHarga: _toDouble(json['total_harga']),
      adminFee: _toDouble(json['admin_fee']),
      komisiPlatform: _toDouble(json['komisi_platform']),
      pendapatanHost: _toDouble(json['pendapatan_host']),
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      namaTempat: json['nama_tempat'] as String?,
      kecamatan: json['kecamatan'] as String?,
      namaTenant: json['nama_tenant'] as String?,
      namaHost: json['nama_host'] as String?,
      foto:
          (json['foto'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      statusLabel: json['status_label'] as String?,
      epassTersedia: json['epass_tersedia'] as bool? ??
          (json['status'] == 'LUNAS' &&
              (json['kode_booking'] as String?) != null),
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
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.tipeDurasi,
    required this.jumlahDurasi,
    required this.hargaSatuan,
    required this.totalHarga,
    this.adminFee = 0,
    required this.komisiPlatform,
    required this.pendapatanHost,
    required this.tersedia,
    required this.jumlahKonflik,
  });

  final String namaTempat;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String tipeDurasi;
  final int jumlahDurasi;
  final double hargaSatuan;
  final double totalHarga;
  final double adminFee;
  final double komisiPlatform;
  final double pendapatanHost;
  final bool tersedia;
  final int jumlahKonflik;

  factory PricePreviewModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) => value is num ? value.toDouble() : 0;

    return PricePreviewModel(
      namaTempat: json['nama_tempat'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      jumlahDurasi: (json['jumlah_durasi'] is num)
          ? (json['jumlah_durasi'] as num).toInt()
          : 0,
      hargaSatuan: toDouble(json['harga_satuan']),
      totalHarga: toDouble(json['total_harga']),
      adminFee: toDouble(json['admin_fee']),
      komisiPlatform: toDouble(json['komisi_platform']),
      pendapatanHost: toDouble(json['pendapatan_host']),
      tersedia: json['tersedia'] as bool? ?? false,
      jumlahKonflik: (json['konflik'] as List<dynamic>?)?.length ?? 0,
    );
  }
}


