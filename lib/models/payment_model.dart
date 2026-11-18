class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.metode,
    required this.jumlah,
    required this.status,
    this.paidAt,
    this.kodeBooking,
    this.totalHarga = 0,
    this.komisiPlatform = 0,
    this.pendapatanHost = 0,
    this.namaTempat,
  });

  final String id;
  final String bookingId;
  final String metode;
  final double jumlah;
  final String status;
  final DateTime? paidAt;
  final String? kodeBooking;
  final double totalHarga;
  final double komisiPlatform;
  final double pendapatanHost;
  final String? namaTempat;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      metode: json['metode'] as String? ?? '',
      jumlah: _toDouble(json['jumlah']),
      status: json['status'] as String? ?? '',
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? ''),
      kodeBooking: json['kode_booking'] as String?,
      totalHarga: _toDouble(json['total_harga']),
      komisiPlatform: _toDouble(json['komisi_platform']),
      pendapatanHost: _toDouble(json['pendapatan_host']),
      namaTempat: json['nama_tempat'] as String?,
    );
  }

  String get metodeLabel => switch (metode) {
    'SIMULASI' => 'Simulasi',
    'TRANSFER' => 'Transfer Bank',
    'QRIS' => 'QRIS',
    'TUNAI' => 'Tunai',
    _ => metode,
  };

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

class EPassModel {
  const EPassModel({
    required this.kodeBooking,
    required this.namaTempat,
    required this.alamat,
    required this.kota,
    required this.jenisUsaha,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahDurasi,
    required this.tipeDurasi,
    required this.totalHarga,
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
  final String kota;
  final String jenisUsaha;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahDurasi;
  final String tipeDurasi;
  final double totalHarga;
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
      kota: json['kota'] as String? ?? '',
      jenisUsaha: json['jenis_usaha'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      jumlahDurasi: json['jumlah_durasi'] is num
          ? (json['jumlah_durasi'] as num).toInt()
          : 0,
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      totalHarga: PaymentModel._toDouble(json['total_harga']),
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
