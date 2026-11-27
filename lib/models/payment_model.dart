class PaymentModel {
  const PaymentModel({
    required this.metode,
    required this.status,
    this.kodeBooking,
    this.redirectUrl,
    this.expiredAt,
  });

  /// Jenis pembayaran dari Midtrans ("MIDTRANS", "qris", "bank_transfer", ...).
  final String metode;

  /// Status pembayaran: PENDING, BERHASIL, GAGAL, EXPIRED, DIBATALKAN.
  final String status;
  final String? kodeBooking;

  /// Link halaman pembayaran Midtrans (Snap) yang dibuka di dalam aplikasi.
  final String? redirectUrl;
  final DateTime? expiredAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      metode: json['metode'] as String? ?? 'MIDTRANS',
      status: json['status'] as String? ?? '',
      kodeBooking: json['kode_booking'] as String?,
      redirectUrl: json['redirect_url'] as String?,
      expiredAt: DateTime.tryParse(json['expired_at'] as String? ?? ''),
    );
  }

  bool get masihMenunggu => status == 'PENDING';

  String get statusLabel => switch (status) {
    'PENDING' => 'Menunggu pembayaran',
    'BERHASIL' => 'Pembayaran berhasil',
    'GAGAL' => 'Pembayaran gagal',
    'EXPIRED' => 'Pembayaran kedaluwarsa',
    'DIBATALKAN' => 'Pembayaran dibatalkan',
    _ => status,
  };

  String get metodeLabel {
    if (metode.toUpperCase() == 'MIDTRANS') return 'Midtrans';

    return metode.replaceAll('_', ' ');
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class EPassModel {
  const EPassModel({
    required this.kodeBooking,
    required this.namaTempat,
    required this.alamat,
    required this.kecamatan,
    required this.jenisUsaha,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahDurasi,
    required this.tipeDurasi,
    required this.totalHarga,
    this.adminFee = 0,
    required this.status,
    this.foto = const [],
    this.namaTenant,
    this.namaHost,
    this.metodePembayaran,
    this.tanggalPembayaran,
  });

  final String kodeBooking;
  final String namaTempat;
  final String alamat;
  final String kecamatan;
  final String jenisUsaha;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahDurasi;
  final String tipeDurasi;
  final double totalHarga;
  final double adminFee;
  final String status;
  final List<String> foto;
  final String? namaTenant;
  final String? namaHost;
  final String? metodePembayaran;
  final DateTime? tanggalPembayaran;

  factory EPassModel.fromJson(Map<String, dynamic> json) {
    return EPassModel(
      kodeBooking: json['kode_booking'] as String? ?? '',
      namaTempat: json['nama_tempat'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      kecamatan: json['kecamatan'] as String? ?? '',
      jenisUsaha: json['jenis_usaha'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      jumlahDurasi: json['jumlah_durasi'] is num
          ? (json['jumlah_durasi'] as num).toInt()
          : 0,
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      totalHarga: _toDouble(json['total_harga']),
      adminFee: _toDouble(json['admin_fee']),
      status: json['status'] as String? ?? '',
      foto:
          (json['foto'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      namaTenant: json['nama_tenant'] as String?,
      namaHost: json['nama_host'] as String?,
      metodePembayaran: json['metode_pembayaran'] as String?,
      tanggalPembayaran: DateTime.tryParse(
        json['tanggal_pembayaran'] as String? ?? '',
      ),
    );
  }
}
