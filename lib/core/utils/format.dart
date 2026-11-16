import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final bilangan = value.round().toString();
  final berpemisah = bilangan.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $berpemisah';
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
