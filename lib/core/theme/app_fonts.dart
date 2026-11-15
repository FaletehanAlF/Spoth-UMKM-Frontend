import 'package:flutter/material.dart';

/// Helper tipografi SPOTH UMKM.
///
/// Judul halaman memakai serif elegan (Playfair Display, font variable
/// terdaftar di pubspec.yaml) untuk kesan premium; teks lainnya memakai
/// font default Material.
abstract final class AppFonts {
  const AppFonts._();

  /// Nama family font serif yang terdaftar di pubspec.
  static const String serifFamily = 'PlayfairDisplay';

  /// Gaya judul halaman (mis. "Temukan Tempat Usahamu").
  static TextStyle serif({
    double weight = 600,
    double? fontSize,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontVariations: [FontVariation('wght', weight)],
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
