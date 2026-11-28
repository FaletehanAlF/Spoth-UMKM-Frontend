import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_colors.dart';

/// Animasi centang sukses untuk pembayaran berhasil / booking LUNAS.
///
/// Memakai Lottie `assets/lottie/success_check.json`. Kalau asset belum
/// siap, fallback ke ikon `check_circle` agar UI tetap rapi.
class SuccessCheckAnimation extends StatelessWidget {
  const SuccessCheckAnimation({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pembayaran berhasil',
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          'assets/lottie/success_check.json',
          repeat: false,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.check_circle,
              size: size,
              color: AppColors.primaryOrange,
            );
          },
        ),
      ),
    );
  }
}
