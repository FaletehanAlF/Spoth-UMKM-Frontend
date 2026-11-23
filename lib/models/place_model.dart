class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.hostId,
    required this.namaTempat,
    required this.kategori,
    required this.deskripsi,
    required this.alamat,
    required this.kota,
    this.fasilitas,
    this.aturan,
    required this.hargaNormal,
    this.hargaPromo,
    required this.hargaEfektif,
    required this.tipeDurasi,
    this.createdAt,
    this.updatedAt,
    this.tanggalMulaiTersedia,
    this.tanggalSelesaiTersedia,
    this.foto = const [],
    this.namaHost,
    this.jumlahFoto = 0,
    this.jadwalTerpakai = const [],
  });

  static const Map<String, String> kategoriLabels = {
    'LAPAK_USAHA': 'Lapak Usaha',
    'TERAS_KOMERSIAL': 'Teras Komersial',
    'BOOTH_EVENT': 'Booth Event',
  };

  static const List<String> kategoriValues = [
    'LAPAK_USAHA',
    'TERAS_KOMERSIAL',
    'BOOTH_EVENT',
  ];

  static const Map<String, String> durasiLabels = {
    'HARIAN': 'Harian',
    'MINGGUAN': 'Mingguan',
    'BULANAN': 'Bulanan',
  };

  static const List<String> durasiValues = ['HARIAN', 'MINGGUAN', 'BULANAN'];

  final String id;
  final String hostId;
  final String namaTempat;
  final String kategori;
  final String deskripsi;
  final String alamat;
  final String kota;
  final String? fasilitas;
  final String? aturan;
  final double hargaNormal;
  final double? hargaPromo;
  final double hargaEfektif;
  final String tipeDurasi;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? tanggalMulaiTersedia;
  final DateTime? tanggalSelesaiTersedia;
  final List<String> foto;
  final String? namaHost;
  final int jumlahFoto;
  final List<BookedRange> jadwalTerpakai;

  String get kategoriLabel => kategoriLabels[kategori] ?? kategori;
  String get durasiLabel => durasiLabels[tipeDurasi] ?? tipeDurasi;
  bool get hasPromo => hargaPromo != null && hargaPromo! < hargaNormal;
  bool get hasPeriodeKetersediaan =>
      tanggalMulaiTersedia != null && tanggalSelesaiTersedia != null;

  List<String> get fasilitasList => (fasilitas ?? '')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      namaTempat: json['nama_tempat'] as String? ?? '',
      kategori: json['kategori'] as String? ?? '',
      deskripsi: json['deskripsi'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      kota: json['kota'] as String? ?? '',
      fasilitas: json['fasilitas'] as String?,
      aturan: json['aturan'] as String?,
      hargaNormal: _toDouble(json['harga_normal']),
      hargaPromo: _toDoubleOrNull(json['harga_promo']),
      hargaEfektif: _toDouble(json['harga_efektif']),
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      tanggalMulaiTersedia: _toDate(json['tanggal_mulai_tersedia']),
      tanggalSelesaiTersedia: _toDate(json['tanggal_selesai_tersedia']),
      foto:
          (json['foto'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      namaHost: json['nama_host'] as String?,
      jumlahFoto: (json['jumlah_foto'] as num?)?.toInt() ?? 0,
      jadwalTerpakai: (json['jadwal_terpakai'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookedRange.fromJson)
          .toList(),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
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

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class BookedRange {
  const BookedRange({
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.status,
  });

  final String tanggalMulai;
  final String tanggalSelesai;
  final String? status;

  factory BookedRange.fromJson(Map<String, dynamic> json) {
    return BookedRange(
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '',
      status: json['status'] as String?,
    );
  }
}

/// Pendapatan bersih host pada satu bulan.
class MonthlyRevenueModel {
  const MonthlyRevenueModel({required this.bulan, required this.pendapatan});

  /// Format YYYY-MM, misalnya "2026-06".
  final String bulan;
  final double pendapatan;

  /// Label pendek untuk sumbu grafik, misalnya "Jun".
  String get labelBulan {
    final bagian = bulan.split('-');
    if (bagian.length != 2) return bulan;

    final nomorBulan = int.tryParse(bagian[1]);
    if (nomorBulan == null || nomorBulan < 1 || nomorBulan > 12) {
      return bulan;
    }

    return _namaBulan[nomorBulan - 1];
  }

  static const List<String> _namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    final nilai = json['pendapatan'];

    return MonthlyRevenueModel(
      bulan: json['bulan'] as String? ?? '',
      pendapatan: nilai is num ? nilai.toDouble() : 0,
    );
  }
}

class PlaceSummaryModel {
  const PlaceSummaryModel({
    required this.totalTempat,
    required this.totalPemesanan,
    required this.pemesananMenunggu,
    required this.pemesananLunas,
    required this.totalPendapatan,
    required this.totalKomisi,
    this.pendapatanBulanan = const [],
  });

  final int totalTempat;
  final int totalPemesanan;
  final int pemesananMenunggu;
  final int pemesananLunas;
  final double totalPendapatan;
  final double totalKomisi;

  /// Pendapatan bersih per bulan dari semua aktivitas, terlama ke terbaru.
  ///
  /// Dibuat nullable agar data lama (misalnya setelah hot reload) tetap aman.
  final List<MonthlyRevenueModel>? pendapatanBulanan;

  factory PlaceSummaryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : 0;
    double toDouble(dynamic value) => value is num ? value.toDouble() : 0;

    final daftarBulanan = json['pendapatan_bulanan'];

    return PlaceSummaryModel(
      totalTempat: toInt(json['total_tempat']),
      totalPemesanan: toInt(json['total_pemesanan']),
      pemesananMenunggu: toInt(json['pemesanan_menunggu']),
      pemesananLunas: toInt(json['pemesanan_lunas']),
      totalPendapatan: toDouble(json['total_pendapatan']),
      totalKomisi: toDouble(json['total_komisi']),
      pendapatanBulanan: daftarBulanan is List
          ? daftarBulanan
                .whereType<Map<String, dynamic>>()
                .map(MonthlyRevenueModel.fromJson)
                .toList()
          : const [],
    );
  }
}
