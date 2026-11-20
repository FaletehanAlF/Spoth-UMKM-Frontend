import 'package:flutter/material.dart';

/// Ikon dan label tampilan untuk kategori tempat.
///
/// Nilai `nama` tetap memakai teks asli dari backend (mis.
/// `LAPAK_USAHA`) agar tidak mengubah kontrak API. Helper ini hanya
/// mengatur bagaimana kategori ditampilkan di UI.
IconData categoryIcon(String nama) {
  switch (nama.toUpperCase()) {
    case 'LAPAK_USAHA':
      return Icons.storefront;
    case 'TERAS_KOMERSIAL':
      return Icons.deck;
    case 'BOOTH_EVENT':
      return Icons.confirmation_number_outlined;
    default:
      return Icons.category_outlined;
  }
}

String categoryLabel(String nama) {
  switch (nama.toUpperCase()) {
    case 'LAPAK_USAHA':
      return 'Lapak Usaha';
    case 'TERAS_KOMERSIAL':
      return 'Teras Komersial';
    case 'BOOTH_EVENT':
      return 'Booth Event';
    default:
      return nama;
  }
}
