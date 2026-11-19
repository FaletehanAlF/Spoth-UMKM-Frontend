import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final bilangan = value.round().toString();
  final berpemisah = bilangan.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $berpemisah';
}

String? namaDepan(String? nama) {
  final bersih = nama?.trim() ?? '';
  if (bersih.isEmpty) return null;

  return bersih.split(RegExp(r'\s+')).first;
}

String? formatDiskonPersen(double hargaNormal, double? hargaPromo) {
  if (hargaPromo == null ||
      hargaPromo <= 0 ||
      hargaNormal <= 0 ||
      hargaPromo >= hargaNormal) {
    return null;
  }

  final persen = (100 - (hargaPromo / hargaNormal * 100)).round();
  if (persen <= 0 || persen > 100) {
    return null;
  }

  return '-$persen%';
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

  switch (tipeDurasi) {
    case 'HARIAN':
      return mulai.add(Duration(days: jumlahDurasi - 1));
    case 'MINGGUAN':
      return mulai.add(Duration(days: jumlahDurasi * 7 - 1));
    case 'BULANAN':
      final bulanTujuan = DateTime.utc(
        mulai.year,
        mulai.month + jumlahDurasi,
        1,
      );
      final hariTerakhir = DateTime.utc(
        bulanTujuan.year,
        bulanTujuan.month + 1,
        0,
      ).day;
      final hari = mulai.day > hariTerakhir ? hariTerakhir : mulai.day;

      return DateTime.utc(
        bulanTujuan.year,
        bulanTujuan.month,
        hari,
      ).subtract(const Duration(days: 1));
    default:
      return mulai;
  }
}

String formatTanggal(DateTime? tanggal) {
  return tanggal == null ? '-' : DateFormat('dd MMM yyyy').format(tanggal);
}

String formatTanggalJam(DateTime? tanggal) {
  return tanggal == null
      ? '-'
      : DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
}
