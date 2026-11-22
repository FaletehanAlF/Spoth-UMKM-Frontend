import 'package:flutter/material.dart';

/// Palet warna SPOTH UMKM — lembut, hangat, dan konsisten.
///
/// Hanya memakai nilai hex; tidak ada gradient atau warna yang acak-acakan.
class AppColors {
  const AppColors._();

  // --- Fondasi putih -------------------------------------------------------
  /// Latar utama aplikasi.
  static const Color canvas = Color(0xFFFFFFFF);

  /// Latar konten sekunder (field, kartu cadetan).
  static const Color surfaceMuted = Color(0xFFFDF9F3);

  /// Latar tipis berkrem (kartu dipilih, ujung slide).
  static const Color lightOrange = Color(0xFFFFF4E8);

  /// Batas halus antar kartu/field.
  static const Color softBorder = Color(0xFFEDE3D4);

  /// Batas yang lebih tenang (garis tipis, teks tipis).
  static const Color neutralBorder = Color(0xFFE1D7C8);

  /// Garis dipetakan — sama seperti surfaceMuted sehingga dasar dipersembahkan.
  static const Color canvasDeep = Color(0xFFFFFFFF);

  // --- Aksen teras (oranye hangat) ------------------------------------------
  /// Aksen utama brand — ikon & aksi aktif.
  static const Color primaryOrange = Color(0xFFFB923C);

  /// Merah oranye untuk tombol & pilihan aktif agar teks putih tetap nyaman.
  static const Color primaryDeep = Color(0xFFF97316);

  /// Aksen ink gelap untuk teks link agar tajam di atas krem.
  static const Color primaryInk = Color(0xFFEA580C);

  // --- Teks -----------------------------------------------------------------
  static const Color darkText = Color(0xFF332D26);
  static const Color charcoal = Color(0xFF2C2621);
  static const Color secondaryText = Color(0xFF6F665B);

  // --- Status ----------------------------------------------------------------
  static const Color sage = Color(0xFF5B7360);
  static const Color sageTint = Color(0xFFEDF3ED);
  static const Color danger = Color(0xFFB4412C);
  static const Color success = Color(0xFF3F7A57);

  /// Putih aksesor.
  static const Color white = Color(0xFFFFFFFF);
}
