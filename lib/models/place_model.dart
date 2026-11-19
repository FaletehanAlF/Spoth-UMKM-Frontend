class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.hostId,
    required this.namaTempat,
    required this.kategori,
    this.deskripsi,
    required this.alamat,
    required this.kota,
    this.fasilitas,
    this.aturan,
    required this.hargaNormal,
    this.hargaPromo,
    required this.hargaEfektif,
    required this.tipeDurasi,
    required this.status,
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
  final String? deskripsi;
  final String alamat;
  final String kota;
  final String? fasilitas;
  final String? aturan;
  final double hargaNormal;
  final double? hargaPromo;
  final double hargaEfektif;
  final String tipeDurasi;
  final String status;
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
  bool get isAktif => status == 'AKTIF';
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
      deskripsi: json['deskripsi'] as String?,
      alamat: json['alamat'] as String? ?? '',
      kota: json['kota'] as String? ?? '',
      fasilitas: json['fasilitas'] as String?,
      aturan: json['aturan'] as String?,
      hargaNormal: _toDouble(json['harga_normal']),
      hargaPromo: _toDoubleOrNull(json['harga_promo']),
      hargaEfektif: _toDouble(json['harga_efektif']),
      tipeDurasi: json['tipe_durasi'] as String? ?? '',
      status: json['status'] as String? ?? 'AKTIF',
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

class PlaceSummaryModel {
  const PlaceSummaryModel({
    required this.totalTempat,
    required this.tempatAktif,
    required this.totalPemesanan,
    required this.pemesananMenunggu,
    required this.pemesananLunas,
    required this.totalPendapatan,
    required this.totalKomisi,
  });

  final int totalTempat;
  final int tempatAktif;
  final int totalPemesanan;
  final int pemesananMenunggu;
  final int pemesananLunas;
  final double totalPendapatan;
  final double totalKomisi;

  factory PlaceSummaryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : 0;
    double toDouble(dynamic value) => value is num ? value.toDouble() : 0;

    return PlaceSummaryModel(
      totalTempat: toInt(json['total_tempat']),
      tempatAktif: toInt(json['tempat_aktif']),
      totalPemesanan: toInt(json['total_pemesanan']),
      pemesananMenunggu: toInt(json['pemesanan_menunggu']),
      pemesananLunas: toInt(json['pemesanan_lunas']),
      totalPendapatan: toDouble(json['total_pendapatan']),
      totalKomisi: toDouble(json['total_komisi']),
    );
  }
}
