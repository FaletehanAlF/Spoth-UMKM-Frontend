import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final bilangan = value.round().toString();
  final berpemisah = bilangan.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $berpemisah';
}

/// Format singkat untuk label grafik, misalnya 1.250.000 menjadi "1,3 jt".
String formatRupiahSingkat(num value) {
  if (value >= 1000000000) {
    return '${_angkaSingkat(value / 1000000000)} M';
  }
  if (value >= 1000000) {
    return '${_angkaSingkat(value / 1000000)} jt';
  }
  if (value >= 1000) {
    return '${_angkaSingkat(value / 1000)} rb';
  }
  return value.round().toString();
}

String _angkaSingkat(double value) {
  final teks = value.toStringAsFixed(1).replaceAll('.', ',');
  return teks.endsWith(',0') ? teks.substring(0, teks.length - 2) : teks;
}

/// Nama bulan lengkap dari kode bulan "YYYY-MM", misalnya "2026-11".
String formatRupiahBulan(String bulan) {
  final bagian = bulan.split('-');
  if (bagian.length != 2) return bulan;

  final nomor = int.tryParse(bagian[1]);
  if (nomor == null || nomor < 1 || nomor > 12) return bulan;

  const nama = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${nama[nomor - 1]} ${bagian[0]}';
}

String? namaDepan(String? nama) {
  final bersih = nama?.trim() ?? '';
  if (bersih.isEmpty) return null;

  return bersih.split(RegExp(r'\s+')).first;
}

String formatDateString(String? tanggal) {
  final nilai = DateTime.tryParse(tanggal ?? '');
  return nilai == null ? '-' : DateFormat('dd MMM yyyy').format(nilai);
}

String formatTanggalApi(DateTime tanggal) {
  final bulan = tanggal.month.toString().padLeft(2, '0');
  final hari = tanggal.day.toString().padLeft(2, '0');
  return '${tanggal.year}-$bulan-$hari';
}

/// Jumlah hari dalam satu paket sewa (1 minggu = 7, 1 bulan = 30).
int hariPerPaket(String tipeDurasi) {
  return tipeDurasi == 'BULANAN' ? 30 : 7;
}

/// Label satuan paket, contoh "minggu" atau "bulan".
String labelSatuan(String tipeDurasi) {
  return tipeDurasi == 'BULANAN' ? 'bulan' : 'minggu';
}

/// Ringkasan durasi siap tampil, contoh "2 minggu (14 hari)".
String labelDurasi(String tipeDurasi, int jumlahDurasi) {
  final hari = hariPerPaket(tipeDurasi) * jumlahDurasi;
  return '$jumlahDurasi ${labelSatuan(tipeDurasi)} ($hari hari)';
}

DateTime tanggalSelesaiSewa(
  DateTime tanggalMulai,
  String tipeDurasi,
  int jumlahDurasi,
) {
  final mulai = DateTime.utc(
    tanggalMulai.year,
    tanggalMulai.month,
    tanggalMulai.day,
  );

  if (jumlahDurasi < 1) {
    return mulai;
  }

  // Tanggal mulai dan tanggal selesai sama-sama dihitung sebagai hari sewa,
  // jadi dikurangi 1 hari: 1 bulan (30 hari) dari 1 Des selesai 30 Des.
  return mulai.add(Duration(days: hariPerPaket(tipeDurasi) * jumlahDurasi - 1));
}

String formatTanggal(DateTime? tanggal) {
  return tanggal == null ? '-' : DateFormat('dd MMM yyyy').format(tanggal);
}

String formatTanggalJam(DateTime? tanggal) {
  return tanggal == null
      ? '-'
      : DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
}
