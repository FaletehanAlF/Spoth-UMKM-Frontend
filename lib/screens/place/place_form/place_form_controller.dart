import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/place_districts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/place_service.dart';
import '../../../core/services/upload_service.dart';
import '../../../models/category_model.dart';
import '../../../models/place_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/place_provider.dart';
import '../../../widgets/category_picker.dart';
import 'place_fields.dart';

class HasilSimpan {
  const HasilSimpan(this.berhasil, this.pesan);

  final bool berhasil;
  final String pesan;
}

class PlaceFormController extends ChangeNotifier {
  PlaceFormController({required this.ref, this.placeId});

  final WidgetRef ref;
  String? placeId;

  static const int maxPhotos = 6;
  static const int maxPhotoBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();
  final alamatController = TextEditingController();
  final hargaMingguanController = TextEditingController();
  final hargaBulananController = TextEditingController();
  final kategoriLainController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String kecamatan = PlaceDistricts.defaultDistrict;
  String kategori = PlaceModel.kategoriValues.first;

  /// Paket yang ditawarkan tempat ini.
  bool paketMingguan = true;
  bool paketBulanan = false;
  List<CategoryModel> categories = const [];
  bool categoriesLoading = false;
  String? categoriesError;
  final List<PhotoItem> photos = [];
  bool loading = false;
  bool submitting = false;
  String? loadError;

  bool get isEditing => (placeId ?? '').isNotEmpty;
  bool get kategoriLain => kategori == CategoryPicker.customValue;

  String get nilaiKategori =>
      kategoriLain ? kategoriLainController.text.trim() : kategori;

  Future<void> init() async {
    await _loadCategories();
    if (isEditing) {
      await _loadExisting();
    }
  }

  Future<void> _loadCategories() async {
    categoriesLoading = true;
    categoriesError = null;
    notifyListeners();

    try {
      categories = await ref.read(placeServiceProvider).listCategories();
    } on Exception catch (error) {
      categoriesError = _pesanError(error);
    } finally {
      categoriesLoading = false;
      notifyListeners();
    }
  }

  String _pesanError(Exception error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return 'Respons daftar kategori tidak valid';
    return 'Gagal memuat kategori';
  }

  Future<void> _loadExisting() async {
    loading = true;
    loadError = null;
    notifyListeners();

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: placeId!, token: token);

      namaController.text = place.namaTempat;
      deskripsiController.text = place.deskripsi;
      alamatController.text = place.alamat;
      kecamatan = place.kecamatan;
      paketMingguan = place.hargaMingguan != null;
      paketBulanan = place.hargaBulanan != null;
      hargaMingguanController.text = place.hargaMingguan == null
          ? ''
          : _trimNumber(place.hargaMingguan!);
      hargaBulananController.text = place.hargaBulanan == null
          ? ''
          : _trimNumber(place.hargaBulanan!);
      kategori = place.kategori;
      if (!categories.any((item) => item.nama == place.kategori)) {
        kategori = CategoryModel.useLainya;
        kategoriLainController.text = place.kategori;
      }

      photos
        ..clear()
        ..addAll(place.foto.map((url) => PhotoItem.existing(url: url)));
    } catch (_) {
      loadError = 'Gagal memuat data tempat';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _trimNumber(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  double? parseHarga(String text) {
    final bersih = text.trim().replaceAll('.', '').replaceAll(',', '.');
    return bersih.isEmpty ? null : double.tryParse(bersih);
  }

  void setKategori(String value) {
    kategori = value;
    notifyListeners();
  }

  void setKecamatan(String value) {
    kecamatan = value;
    notifyListeners();
  }

  void setPaketMingguan(bool aktif) {
    paketMingguan = aktif;
    notifyListeners();
  }

  void setPaketBulanan(bool aktif) {
    paketBulanan = aktif;
    notifyListeners();
  }

  Future<String?> tambahFoto(ImageSource sumber) async {
    if (photos.length >= maxPhotos) {
      return 'Maksimal $maxPhotos foto.';
    }

    if (sumber == ImageSource.camera) {
      final izin = await PermissionService.ensureCameraPermission();
      if (!izin) return 'Izin kamera tidak diizinkan.';
    }

    try {
      final picked = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      if (await picked.length() > maxPhotoBytes) {
        return 'Ukuran foto maksimal ${maxPhotoBytes ~/ (1024 * 1024)} MB.';
      }

      final nama = picked.name.isNotEmpty
          ? picked.name
          : 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final titik = nama.lastIndexOf('.');
      final ext = titik >= 0 ? nama.substring(titik + 1).toLowerCase() : '';

      if (!_allowedExtensions.contains(ext)) {
        return 'Format foto harus JPG, JPEG, PNG, atau WEBP.';
      }

      photos.add(
        PhotoItem.newLocal(bytes: await picked.readAsBytes(), filename: nama),
      );
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal memilih foto. Coba lagi.';
    }
  }

  void hapusFoto(int index) {
    photos.removeAt(index);
    notifyListeners();
  }

  Future<HasilSimpan> simpan() async {
    if (submitting) {
      return const HasilSimpan(false, 'Sedang menyimpan.');
    }

    if (photos.isEmpty) {
      return const HasilSimpan(false, 'Tambahkan minimal 1 foto tempat.');
    }

    if (!paketMingguan && !paketBulanan) {
      return const HasilSimpan(
        false,
        'Aktifkan minimal satu paket: mingguan atau bulanan.',
      );
    }

    final hargaMingguan = paketMingguan
        ? parseHarga(hargaMingguanController.text)
        : null;
    final hargaBulanan = paketBulanan
        ? parseHarga(hargaBulananController.text)
        : null;

    if (paketMingguan && (hargaMingguan == null || hargaMingguan <= 0)) {
      return const HasilSimpan(false, 'Harga paket mingguan tidak valid.');
    }

    if (paketBulanan && (hargaBulanan == null || hargaBulanan <= 0)) {
      return const HasilSimpan(false, 'Harga paket bulanan tidak valid.');
    }

    if (nilaiKategori.trim().isEmpty) {
      return const HasilSimpan(false, 'Kategori tempat wajib diisi.');
    }

    if (nilaiKategori.trim().length > 50) {
      return const HasilSimpan(false, 'Kategori maksimal 50 karakter.');
    }

    submitting = true;
    notifyListeners();

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) {
        return const HasilSimpan(false, 'Sesi login berakhir. Masuk ulang.');
      }

      final fotoUrls = <String>[
        for (final foto in photos)
          if (foto.url != null) foto.url!,
      ];

      for (final foto in photos) {
        if (foto.bytes == null) continue;

        try {
          final hasil = await ref
              .read(uploadServiceProvider)
              .uploadPhoto(
                token: token,
                filename: foto.filename ?? 'foto.jpg',
                bytes: foto.bytes!,
              );
          fotoUrls.add(hasil.secureUrl);
        } catch (_) {
          return const HasilSimpan(
            false,
            'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.',
          );
        }
      }

      final payload = <String, dynamic>{
        'nama_tempat': namaController.text.trim(),
        'kategori': nilaiKategori.trim(),
        'alamat': alamatController.text.trim(),
        'kecamatan': kecamatan,
        'harga_mingguan': hargaMingguan,
        'harga_bulanan': hargaBulanan,
        'deskripsi': deskripsiController.text.trim(),
        'foto': fotoUrls,
      };

      final service = ref.read(placeServiceProvider);

      if (isEditing) {
        await service.updatePlace(
          token: token,
          id: placeId!,
          payload: payload,
        );
      } else {
        await service.createPlace(token: token, payload: payload);
      }

      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();
      await ref.read(tenantPlacesProvider.notifier).refresh();

      return HasilSimpan(
        true,
        isEditing ? 'Tempat berhasil diperbarui.' : 'Tempat berhasil ditambahkan.',
      );
    } catch (_) {
      return const HasilSimpan(false, 'Gagal menyimpan tempat. Coba lagi.');
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in [
      namaController,
      deskripsiController,
      alamatController,
      hargaMingguanController,
      hargaBulananController,
      kategoriLainController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
