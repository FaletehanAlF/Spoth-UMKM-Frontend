import 'package:flutter/material.dart';

import '../core/constants/category_style.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../models/category_model.dart';

/// Pemilih kategori untuk form tambah/edit tempat.
///
/// Kategori preset ditampilkan sebagai chip berikon, sedangkan opsi
/// "Lainnya" membuka input teks bebas. Nilai yang dikirim ke backend tetap
/// `nama` asli kategori.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// Nilai sentinel untuk opsi "Lainnya".
  static const String customValue = 'Lainnya';

  final List<CategoryModel> categories;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final unik = <String>{};
    final namaKategori = [
      for (final item in categories)
        if (unik.add(item.nama)) item.nama,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final nama in namaKategori)
                _CategoryChip(
                  label: categoryLabel(nama),
                  icon: categoryIcon(nama),
                  selected: selected == nama,
                  enabled: enabled,
                  onTap: () => onChanged(nama),
                ),
              _CategoryChip(
                label: customValue,
                icon: Icons.edit_outlined,
                selected: selected == customValue,
                enabled: enabled,
                onTap: () => onChanged(customValue),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            selected == customValue
                ? 'Tulis nama kategori sendiri di kolom bawah.'
                : 'Pilih kategori yang paling sesuai dengan tempatmu.',
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.primaryDeep : AppColors.white;
    final foreground = selected ? AppColors.white : AppColors.charcoal;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primaryDeep : AppColors.softBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_rounded, size: 15, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
