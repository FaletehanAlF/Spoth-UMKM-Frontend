import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../models/user_model.dart';

/// Kartu identitas profil.
///
/// Pada mode lihat, kartu ini hanya menampilkan data dan satu tombol
/// **Edit Profil**. Pada mode edit, tombol ganti/hapus foto muncul agar
/// pengguna bisa memperbarui avatar sebelum menyimpan perubahan.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.user,
    required this.fotoUrl,
    required this.isEditing,
    required this.isUploading,
    required this.onEdit,
    required this.onGantiFoto,
    required this.onHapusFoto,
  });

  final UserModel user;
  final String? fotoUrl;
  final bool isEditing;
  final bool isUploading;
  final VoidCallback onEdit;
  final VoidCallback onGantiFoto;
  final VoidCallback onHapusFoto;

  bool get _punyaFoto => (fotoUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(fotoUrl: fotoUrl, nama: user.nama),
                if (isEditing)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Tooltip(
                      message: 'Ganti foto',
                      child: Material(
                        color: AppColors.primaryDeep,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isUploading ? null : onGantiFoto,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: isUploading
                                ? const Padding(
                                    padding: EdgeInsets.all(9),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 17,
                                    color: AppColors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            user.nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(child: _RoleBadge(role: user.role)),
          const SizedBox(height: AppSpacing.xl),
          if (isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUploading ? null : onGantiFoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(isUploading ? 'Mengunggah...' : 'Ganti Foto'),
                  ),
                ),
                if (_punyaFoto) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    onPressed: isUploading ? null : onHapusFoto,
                    tooltip: 'Hapus foto',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Foto baru diterapkan setelah kamu menekan Simpan Perubahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profil'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.fotoUrl, required this.nama});

  final String? fotoUrl;
  final String nama;

  @override
  Widget build(BuildContext context) {
    final url = (fotoUrl ?? '').trim();

    return Container(
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: url.isEmpty
          ? _InitialAvatar(nama: nama)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialAvatar(nama: nama),
            ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    final bersih = nama.trim();
    final inisial = bersih.isEmpty
        ? '?'
        : bersih
              .split(RegExp(r'\s+'))
              .take(2)
              .map((bagian) => bagian[0].toUpperCase())
              .join();

    return Container(
      color: AppColors.lightOrange,
      alignment: Alignment.center,
      child: Text(
        inisial,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isHost = role == UserModel.roleHost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHost ? AppColors.sageTint : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isHost ? 'Pemilik Tempat' : 'Penyewa',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isHost ? AppColors.sage : AppColors.primaryInk,
        ),
      ),
    );
  }
}
