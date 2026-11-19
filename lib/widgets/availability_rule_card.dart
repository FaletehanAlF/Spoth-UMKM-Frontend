import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/format.dart';
import '../models/availability_model.dart';

class AvailabilityRuleCard extends StatelessWidget {
  const AvailabilityRuleCard({
    super.key,
    required this.rule,
    this.onEdit,
    this.onDelete,
  });

  final AvailabilityRuleModel rule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  IconData get _icon {
    switch (rule.tipeAturan) {
      case 'HARI':
        return Icons.event_repeat_outlined;
      case 'BULAN':
        return Icons.calendar_month_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final adaAksi = onEdit != null || onDelete != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: rule.tersedia
                  ? AppColors.lightOrange
                  : AppColors.softBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _icon,
              size: 18,
              color: rule.tersedia ? AppColors.primaryOrange : errorColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Aturan ${rule.tipeLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(tersedia: rule.tersedia),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rule.sasaranLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDateString(rule.tanggalMulai)} - '
                  '${formatDateString(rule.tanggalSelesai)}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (rule.memblokir) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Jadwal yang cocok tidak dapat dipesan.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: errorColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (adaAksi) ...[
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  _AksiButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Ubah aturan',
                    onPressed: onEdit!,
                  ),
                if (onDelete != null)
                  _AksiButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Hapus aturan',
                    onPressed: onDelete!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.tersedia});

  final bool tersedia;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tersedia
            ? AppColors.lightOrange
            : errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tersedia ? 'Tersedia' : 'Tidak tersedia',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: tersedia ? AppColors.primaryOrange : errorColor,
        ),
      ),
    );
  }
}

class _AksiButton extends StatelessWidget {
  const _AksiButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        color: AppColors.secondaryText,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
