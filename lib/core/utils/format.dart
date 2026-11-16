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

String formatTanggal(DateTime? tanggal) {
  return tanggal == null ? '-' : DateFormat('dd MMM yyyy').format(tanggal);
}

String formatTanggalJam(DateTime? tanggal) {
  return tanggal == null
      ? '-'
      : DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
}
