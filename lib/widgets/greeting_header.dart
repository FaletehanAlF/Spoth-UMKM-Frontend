import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Sapaan sambutan berisi nama akun yang sedang login.
/// Dipakai bersama oleh Home Pemilik dan Home Penyewa.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.displayName,
    this.subtitle = 'Mau booking tempat apa hari ini?',
  });

  final String displayName;

  /// Kalimat pembuka di bawah nama (menyesuaikan role halaman).
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryOrange,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
