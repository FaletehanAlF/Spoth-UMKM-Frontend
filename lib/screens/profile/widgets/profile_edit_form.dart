import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';

/// Form edit profil.
///
/// Controller dimiliki oleh [ProfileScreen] agar nilai awal, pembatalan, dan
/// penyimpanan tetap berada di satu tempat. Widget ini hanya mengatur
/// tampilan serta validasi input.
class ProfileEditForm extends StatelessWidget {
  const ProfileEditForm({
    super.key,
    required this.formKey,
    required this.namaController,
    required this.emailController,
    required this.noHpController,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController namaController;
  final TextEditingController emailController;
  final TextEditingController noHpController;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Profil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Perbarui data di bawah, lalu simpan untuk menerapkan perubahan.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: namaController,
              textCapitalization: TextCapitalization.words,
              enabled: !isSaving,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Nama wajib diisi';
                if (text.length < 5) return 'Nama minimal 5 karakter';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: emailController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
                helperText: 'Email tidak dapat diubah dari halaman ini.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: noHpController,
              enabled: !isSaving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No. HP',
                hintText: 'Contoh: 081234567890',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Simpan Perubahan'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
