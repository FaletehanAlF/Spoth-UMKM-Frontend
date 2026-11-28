import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Foto profil kontak chat; fallback huruf pertama jika foto kosong/rusak.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim() ?? '';
    final safeName = name.trim();
    final initial = safeName.isEmpty ? '?' : safeName.substring(0, 1).toUpperCase();

    Widget fallback() => Text(
      initial,
      style: const TextStyle(
        color: AppColors.primaryDeep,
        fontWeight: FontWeight.w700,
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: AppColors.lightOrange,
          child: image.isEmpty
              ? Center(child: fallback())
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(child: fallback()),
                ),
        ),
      ),
    );
  }
}
