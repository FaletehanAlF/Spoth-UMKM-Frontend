import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/place_districts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../models/category_model.dart';
import '../../../models/place_model.dart';
import '../../../widgets/category_picker.dart';
import '../../../widgets/shimmer_loading.dart';

class PhotoItem {
  PhotoItem.existing({required this.url}) : bytes = null, filename = null;

  PhotoItem.newLocal({required this.bytes, required this.filename}) : url = null;

  final String? url;
  final Uint8List? bytes;
  final String? filename;

  bool get isBaru => bytes != null;
}

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primaryDeep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class InfoFields extends StatelessWidget {
  const InfoFields({
    super.key,
    required this.namaController,
    required this.alamatController,
    required this.deskripsiController,
    required this.kategoriLainController,
    required this.kategori,
    required this.onKategoriChanged,
    required this.kecamatan,
    required this.onKecamatanChanged,
    required this.categories,
    required this.categoriesLoading,
    required this.categoriesError,
    required this.onRetryCategories,
    required this.enabled,
  });

  final TextEditingController namaController;
  final TextEditingController alamatController;
  final TextEditingController deskripsiController;
  final TextEditingController kategoriLainController;
  final String kategori;
  final ValueChanged<String> onKategoriChanged;
  final String kecamatan;
  final ValueChanged<String> onKecamatanChanged;
  final List<CategoryModel> categories;
  final bool categoriesLoading;
  final String? categoriesError;
  final VoidCallback onRetryCategories;
  final bool enabled;

  bool get _kategoriLain => kategori == CategoryPicker.customValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: namaController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Tempat',
            hintText: 'Contoh: Lapak Kuliner Pasar Baru',
          ),
          validator: (value) {
            final teks = value?.trim() ?? '';
            if (teks.isEmpty) return 'Nama tempat wajib diisi';
            if (teks.length < 5) return 'Nama tempat minimal 5 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        if (categoriesLoading)
          const _PickerSkeleton()
        else if (categoriesError != null)
          _PickerError(onRetry: onRetryCategories)
        else ...[
          CategoryPicker(
            categories: categories,
            selected: kategori,
            enabled: enabled,
            onChanged: onKategoriChanged,
          ),
          if (_kategoriLain) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: kategoriLainController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori Baru',
                hintText: 'Contoh: Warung Minuman',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              enabled: enabled,
              validator: (value) {
                final teks = value?.trim() ?? '';
                if (teks.isEmpty) return 'Nama kategori lain wajib diisi';
                if (teks.length < 5) return 'Nama kategori minimal 5 karakter';
                return null;
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: deskripsiController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Deskripsi',
            hintText: 'Contoh: Lapak makan malam dengan area parkir',
          ),
          validator: (value) {
            final teks = value?.trim() ?? '';
            if (teks.isEmpty) return 'Deskripsi wajib diisi';
            if (teks.length < 10) return 'Deskripsi minimal 10 karakter';
            if (teks.length > 250) return 'Deskripsi maksimal 250 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: kecamatan,
          decoration: const InputDecoration(labelText: 'Kecamatan'),
          items: [
            for (final item in PlaceDistricts.depok)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) onKecamatanChanged(value);
                }
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: alamatController,
          decoration: const InputDecoration(
            labelText: 'Alamat',
            hintText: 'Contoh: Jl. Merdeka No. 10',
          ),
          validator: (value) {
            final teks = value?.trim() ?? '';
            if (teks.isEmpty) return 'Alamat wajib diisi';
            if (teks.length < 10) return 'Alamat minimal 10 karakter';
            return null;
          },
        ),
      ],
    );
  }
}

class _PickerSkeleton extends StatelessWidget {
  const _PickerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          ShimmerBox(width: 116, height: 40, radius: AppRadius.pill),
          ShimmerBox(width: 132, height: 40, radius: AppRadius.pill),
          ShimmerBox(width: 104, height: 40, radius: AppRadius.pill),
          ShimmerBox(width: 88, height: 40, radius: AppRadius.pill),
        ],
      ),
    );
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gagal memuat kategori.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class PhotoFields extends StatelessWidget {
  const PhotoFields({
    super.key,
    required this.photos,
    required this.maxPhotos,
    required this.maxPhotoBytes,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PhotoItem> photos;
  final int maxPhotos;
  final int maxPhotoBytes;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final mb = (maxPhotoBytes / (1024 * 1024)).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Maks. $maxPhotos foto, minimal 1. Format JPG, JPEG, PNG, WEBP, '
          'maks $mb MB per foto.',
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final kolom = constraints.maxWidth >= 720
                ? 5
                : constraints.maxWidth >= 480
                ? 4
                : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kolom,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: photos.length + (photos.length < maxPhotos ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  return _PhotoThumb(
                    photo: photos[index],
                    onRemove: () => onRemove(index),
                  );
                }

                return _AddPhotoTile(onTap: onAdd);
              },
            );
          },
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onRemove});

  final PhotoItem photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider = photo.bytes != null
        ? MemoryImage(photo.bytes!)
        : NetworkImage(photo.url!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: provider,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.lightOrange,
              child: Icon(Icons.storefront, color: AppColors.primaryDeep),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: AppColors.charcoal.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, size: 16, color: AppColors.white),
                ),
              ),
            ),
          ),
          if (photo.isBaru)
            const Positioned(left: 4, bottom: 4, child: _MiniBadge()),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightOrange,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primaryInk),
            SizedBox(height: 6),
            Text(
              'Tambah Foto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BARU',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class PriceDurationFields extends StatelessWidget {
  const PriceDurationFields({
    super.key,
    required this.hargaController,
    required this.tipeDurasi,
    required this.onTipeDurasiChanged,
    required this.enabled,
  });

  final TextEditingController hargaController;
  final String tipeDurasi;
  final ValueChanged<String> onTipeDurasiChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: hargaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Harga Sewa',
            prefixText: 'Rp ',
            hintText: 'Contoh: 250000',
          ),
          validator: (value) {
            final teks = (value ?? '').trim();
            if (teks.isEmpty) return 'Harga wajib diisi';

            final angka = double.tryParse(
              teks.replaceAll('.', '').replaceAll(',', '.'),
            );
            if (angka == null || angka <= 0) return 'Harga harus berupa angka';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Durasi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final durasi in PlaceModel.durasiValues)
              ChoiceChip(
                label: Text(PlaceModel.durasiLabels[durasi] ?? durasi),
                selected: tipeDurasi == durasi,
                selectedColor: AppColors.primaryDeep,
                labelStyle: TextStyle(
                  color: tipeDurasi == durasi
                      ? AppColors.white
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: enabled ? (_) => onTipeDurasiChanged(durasi) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class PeriodFields extends StatelessWidget {
  const PeriodFields({
    super.key,
    required this.mulaiController,
    required this.selesaiController,
    required this.isEditing,
    required this.onPickMulai,
    required this.onPickSelesai,
  });

  final TextEditingController mulaiController;
  final TextEditingController selesaiController;
  final bool isEditing;
  final VoidCallback onPickMulai;
  final VoidCallback onPickSelesai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditing
              ? 'Tempat hanya dapat disewa dalam rentang tanggal ini. '
                    'Kosongkan keduanya bila tidak dibatasi.'
              : 'Tempat hanya dapat disewa dalam rentang tanggal ini. '
                    'Kedua tanggal wajib diisi.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: mulaiController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Tanggal mulai',
            hintText: 'Pilih tanggal mulai',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: onPickMulai,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: selesaiController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Tanggal selesai',
            hintText: 'Pilih tanggal selesai',
            prefixIcon: Icon(Icons.event_available_outlined),
          ),
          onTap: onPickSelesai,
        ),
      ],
    );
  }
}
