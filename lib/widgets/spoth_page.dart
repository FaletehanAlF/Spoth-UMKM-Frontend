import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';

/// Membatasi lebar konten dan memusatkannya di layar lebar.
class SpothPageBody extends StatelessWidget {
  const SpothPageBody({
    super.key,
    required this.child,
    this.maxWidth = AppWidth.page,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Judul bagian dengan aksi opsional di sisi kanan.
class SpothSectionHeader extends StatelessWidget {
  const SpothSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.charcoal,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}
