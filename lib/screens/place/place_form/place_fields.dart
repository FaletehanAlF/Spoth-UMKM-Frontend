import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/place_districts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../models/category_model.dart';
import '../../../widgets/category_picker.dart';
import '../../../widgets/shimmer_loading.dart';

class LokasiFields extends StatelessWidget {
  const LokasiFields({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.membacaLokasi,
    required this.onGunakanLokasiSaatIni,
    required this.onCariKoordinatDariAlamat,
    required this.onHapusLokasi,
    required this.enabled,
  });

  final double? latitude;
  final double? longitude;
  final bool membacaLokasi;
  final VoidCallback onGunakanLokasiSaatIni;
  final VoidCallback onCariKoordinatDariAlamat;
  final VoidCallback onHapusLokasi;
  final bool enabled;

  bool get punyaLokasi => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final aktif = enabled && !membacaLokasi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Alamat lengkap diisi di atas. Koordinat dipakai untuk peta.',
          style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: aktif ? onGunakanLokasiSaatIni : null,
          icon: const Icon(Icons.my_location, size: 18),
          label: Text(membacaLokasi ? 'Mengambil lokasi...' : 'Gunakan lokasi saat ini'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: aktif ? onCariKoordinatDariAlamat : null,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Cari koordinat dari alamat'),
        ),
        const SizedBox(height: 12),
        if (punyaLokasi) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latitude ${latitude!.toStringAsFixed(6)}, Longitude ${longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.charcoal),
                  ),
                ),
                TextButton(
                  onPressed: enabled ? onHapusLokasi : null,
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ),
        ] else
          Text(
            'Lokasi peta opsional. Isi alamat lengkap tetap wajib.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
          ),
      ],
    );
  }
}

class PhotoItem {
  PhotoItem.existing({required this.url}) : bytes = null, filename = null;

  PhotoItem.newLocal({required this.bytes, required this.filename}) : url = null;

  final String? url;
  final Uint8List? bytes;
  final String? filename;

  bool get isBaru => bytes != null;
}

class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
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

  Widget _fieldNama() {
    return TextFormField(
      controller: namaController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Nama Tempat'),
      validator: (value) {
        final teks = value?.trim() ?? '';
        if (teks.isEmpty) return 'Nama tempat wajib diisi';
        if (teks.length < 5) return 'Nama tempat minimal 5 karakter';
        return null;
      },
    );
  }

  Widget _fieldKategori() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  Widget _fieldDeskripsi() {
    return TextFormField(
      controller: deskripsiController,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Deskripsi'),
      validator: (value) {
        final teks = value?.trim() ?? '';
        if (teks.isEmpty) return 'Deskripsi wajib diisi';
        if (teks.length < 30) return 'Deskripsi minimal 30 karakter';
        return null;
      },
    );
  }

  Widget _fieldKecamatan() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _fieldAlamat() {
    return TextFormField(
      controller: alamatController,
      decoration: const InputDecoration(labelText: 'Alamat'),
      validator: (value) {
        final teks = value?.trim() ?? '';
        if (teks.isEmpty) return 'Alamat wajib diisi';
        if (teks.length < 10) return 'Alamat minimal 10 karakter';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final duaKolom = constraints.maxWidth >= 700;

        final fieldsBawah = duaKolom
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _fieldDeskripsi()),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldKecamatan(),
                        const SizedBox(height: 16),
                        _fieldAlamat(),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fieldDeskripsi(),
                  const SizedBox(height: 16),
                  _fieldKecamatan(),
                  const SizedBox(height: 16),
                  _fieldAlamat(),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldNama(),
            const SizedBox(height: 16),
            _fieldKategori(),
            const SizedBox(height: 16),
            fieldsBawah,
          ],
        );
      },
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
    required this.onAdd,
    required this.onRemove,
  });

  final List<PhotoItem> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    required this.paketMingguan,
    required this.paketBulanan,
    required this.hargaMingguanController,
    required this.hargaBulananController,
    required this.onPaketMingguanChanged,
    required this.onPaketBulananChanged,
    required this.enabled,
  });

  final bool paketMingguan;
  final bool paketBulanan;
  final TextEditingController hargaMingguanController;
  final TextEditingController hargaBulananController;
  final ValueChanged<bool> onPaketMingguanChanged;
  final ValueChanged<bool> onPaketBulananChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlokPaket(
          judul: 'Mingguan',
          labelHarga: 'Harga per minggu',
          aktif: paketMingguan,
          onAktifChanged: enabled ? onPaketMingguanChanged : null,
          controller: hargaMingguanController,
          enabled: enabled && paketMingguan,
        ),
        const SizedBox(height: 12),
        _BlokPaket(
          judul: 'Bulanan',
          labelHarga: 'Harga per bulan',
          aktif: paketBulanan,
          onAktifChanged: enabled ? onPaketBulananChanged : null,
          controller: hargaBulananController,
          enabled: enabled && paketBulanan,
        ),
      ],
    );
  }
}

class _BlokPaket extends StatelessWidget {
  const _BlokPaket({
    required this.judul,
    required this.labelHarga,
    required this.aktif,
    required this.onAktifChanged,
    required this.controller,
    required this.enabled,
  });

  final String judul;
  final String labelHarga;
  final bool aktif;
  final ValueChanged<bool>? onAktifChanged;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: aktif ? AppColors.surfaceMuted : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: aktif ? AppColors.primaryDeep : AppColors.softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Switch(
                value: aktif,
                onChanged: onAktifChanged,
              ),
            ],
          ),
          if (aktif) ...[
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: labelHarga,
                prefixText: 'Rp ',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.charcoal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.charcoal,
                    width: 1.6,
                  ),
                ),
              ),
              validator: (value) {
                if (!aktif) return null;

                final teks = (value ?? '').trim();
                if (teks.isEmpty) return 'Harga wajib diisi';

                final angka = double.tryParse(
                  teks.replaceAll('.', '').replaceAll(',', '.'),
                );
                if (angka == null || angka <= 0) {
                  return 'Harga harus berupa angka';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
