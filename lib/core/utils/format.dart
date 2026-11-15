import 'package:intl/intl.dart';

/// Util format tampilan (rupiah & tanggal) agar konsisten di seluruh halaman.

/// Memformat angka menjadi teks rupiah, contoh: `Rp 1.250.000`.
String formatRupiah(num value) {
  final bilangan = value.round().toString();
  final berpemisah = bilangan.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $berpemisah';
}

/// Memformat string tanggal ISO / `YYYY-MM-DD` menjadi `dd MMM yyyy`.
String formatDateString(String? tanggal) {
  final nilai = DateTime.tryParse(tanggal ?? '');
  return nilai == null ? '-' : DateFormat('dd MMM yyyy').format(nilai);
}

/// Memformat [DateTime] menjadi `dd MMM yyyy`.
String formatTanggal(DateTime? tanggal) {
  return tanggal == null ? '-' : DateFormat('dd MMM yyyy').format(tanggal);
}

/// Memformat [DateTime] menjadi `dd MMM yyyy, HH:mm`.
String formatTanggalJam(DateTime? tanggal) {
  return tanggal == null
      ? '-'
      : DateFormat('dd MMM yyyy, HH:mm').format(tanggal);
}
