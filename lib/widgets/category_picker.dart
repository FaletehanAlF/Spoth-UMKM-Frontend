import 'package:flutter/material.dart';

import '../core/constants/category_style.dart' show categoryLabel;
import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../models/category_model.dart';

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
    final namaKategori = <String>[
      for (final item in categories)
        if (item.isPreset) item.nama,
    ];
    if (!namaKategori.contains(selected) && selected != customValue) {
      namaKategori.add(selected);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final nama in namaKategori)
              _CategoryChip(
                label: categoryLabel(nama),
                selected: selected == nama,
                enabled: enabled,
                onTap: () => onChanged(nama),
              ),
            _CategoryChip(
              label: customValue,
              selected: selected == customValue,
              enabled: enabled,
              onTap: () => onChanged(customValue),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
