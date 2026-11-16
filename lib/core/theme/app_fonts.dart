import 'package:flutter/material.dart';

abstract final class AppFonts {
  const AppFonts._();

  static const String fontFamily = 'Montserrat';

  static TextStyle heading({
    double weight = 600,
    double? fontSize,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontVariations: [FontVariation('wght', weight)],
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
