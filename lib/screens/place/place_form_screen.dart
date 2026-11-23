import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/api_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/place_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/format.dart';
import '../../models/category_model.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/availability_rule_section.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';

class _PhotoItem {
  _PhotoItem.existing({required this.url}) : bytes = null, filename = null;

  _PhotoItem.newLocal({required this.bytes, required this.filename})
    : url = null;

  final String? url;

  final Uint8List? bytes;

  final String? filename;
}

class PlaceFormScreen extends ConsumerStatefulWidget {
  const PlaceFormScreen({super.key, this.placeId});

  final String? placeId;

  @override
  ConsumerState<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends ConsumerState<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _kotaController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _aturanController = TextEditingController();
  final _hargaNormalController = TextEditingController();
  final _hargaPromoController = TextEditingController();
  final _tanggalMulaiController = TextEditingController();
  final _tanggalSelesaiController = TextEditingController();

  static const int _maxPhotos = 6;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  String _kategori = PlaceModel.kategoriValues.first;
  final _kategoriLainController = TextEditingController();
  static const String _kategoriLain = CategoryPicker.customValue;
  bool get _isKategoriCustom => _kategori == _kategoriLain;
  List<CategoryModel> _categories = const [];
  bool _categoriesLoading = false;
  String? _categoriesError;

  /// Kategorienya dikirim ke backend; kalau mode lainya maka dari teks.
  String get _kategoriValue =>
      _isKategoriCustom ? _kategoriLainController.text.trim() : _kategori;
  String _tipeDurasi = PlaceModel.durasiValues.first;
  String? _placeId;
  DateTime? _tanggalMulaiTersedia;
  DateTime? _tanggalSelesaiTersedia;
  bool _loading = false;
  bool _submitting = false;
  String? _loadError;

  final List<_PhotoItem> _photos = [];
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => (_placeId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _placeId = widget.placeId;
    _loadCategories();
    if (_isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final categories = await ref.read(placeServiceProvider).listCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _categoriesError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  String _errorMessage(Exception error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Respons daftar kategori tidak valid';
    }
    return 'Gagal memuat kategori';
  }

  @override
  void dispose() {
    for (final controller in [
      _namaController,
      _deskripsiController,
      _alamatController,
      _kotaController,
      _fasilitasController,
      _aturanController,
      _hargaNormalController,
      _hargaPromoController,
      _tanggalMulaiController,
      _tanggalSelesaiController,
      _kategoriLainController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      final place = await ref
          .read(placeServiceProvider)
          .getPlaceDetail(id: _placeId!, token: token);

      if (!mounted) return;
      _namaController.text = place.namaTempat;
      _deskripsiController.text = place.deskripsi;
      _alamatController.text = place.alamat;
      _kotaController.text = place.kota;
      _fasilitasController.text = (place.fasilitas ?? '').trim();
      _aturanController.text = place.aturan ?? '';
      _hargaNormalController.text = _trimNumber(place.hargaNormal);
      _hargaPromoController.text = place.hargaPromo == null
          ? ''
          : _trimNumber(place.hargaPromo!);
      _kategori = place.kategori;
      if (!_categories.any((item) => item.nama == place.kategori)) {
        setState(() {
          _kategori = CategoryModel.useLainya;
          _kategoriLainController.text = place.kategori;
        });
      }
      _tipeDurasi = place.tipeDurasi;
      _tanggalMulaiTersedia = place.tanggalMulaiTersedia;
      _tanggalSelesaiTersedia = place.tanggalSelesaiTersedia;
      _tanggalMulaiController.text = place.tanggalMulaiTersedia == null
          ? ''
          : formatTanggal(place.tanggalMulaiTersedia);
      _tanggalSelesaiController.text = place.tanggalSelesaiTersedia == null
          ? ''
          : formatTanggal(place.tanggalSelesaiTersedia);
      _photos
        ..clear()
        ..addAll(place.foto.map((url) => _PhotoItem.existing(url: url)));
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Gagal memuat data tempat');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _trimNumber(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  double? _parseHarga(String text) {
    final bersih = text.trim().replaceAll('.', '').replaceAll(',', '.');
    return bersih.isEmpty ? null : double.tryParse(bersih);
  }

  Future<void> _pilihTanggalKetersediaan({required bool mulai}) async {
    final hariIni = DateTime.now();
    final awal = mulai
        ? _tanggalMulaiTersedia
        : _tanggalSelesaiTersedia ?? _tanggalMulaiTersedia;
    final pertama = mulai
        ? DateTime(2000)
        : _tanggalMulaiTersedia ?? DateTime(2000);
    final terakhir = DateTime(hariIni.year + 10, 12, 31);
    final dasar = awal ?? hariIni;
    final initial = dasar.isBefore(pertama)
        ? pertama
        : dasar.isAfter(terakhir)
        ? terakhir
        : dasar;

    final dipilih = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: pertama,
      lastDate: terakhir,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primaryOrange),
        ),
        child: child!,
      ),
    );

    if (dipilih == null || !mounted) {
      return;
    }

    setState(() {
      if (mulai) {
        _tanggalMulaiTersedia = dipilih;
        _tanggalMulaiController.text = formatTanggal(dipilih);
        if (_tanggalSelesaiTersedia != null &&
            _tanggalSelesaiTersedia!.isBefore(dipilih)) {
          _tanggalSelesaiTersedia = dipilih;
          _tanggalSelesaiController.text = formatTanggal(dipilih);
        }
      } else {
        _tanggalSelesaiTersedia = dipilih;
        _tanggalSelesaiController.text = formatTanggal(dipilih);
      }
    });
  }

  void _showSnack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _showPickSheet() async {
    if (_photos.length >= _maxPhotos) {
      _showSnack('Maksimal $_maxPhotos foto.');
      return;
    }

    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text(
                    'Tambah foto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_photos.length}/$_maxPhotos',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryOrange,
              ),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primaryOrange,
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (sumber != null) {
      await _addPhotoFromSource(sumber);
    }
  }

  Future<void> _addPhotoFromSource(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await PermissionService.ensureCameraPermission();
      if (!granted) {
        _showSnack('Izin kamera tidak diizinkan â€” tidak bisa ambil foto.');
        return;
      }
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final size = await picked.length();
      if (size > _maxPhotoBytes) {
        _showSnack('Ukuran foto maksimal 5 MB.');
        return;
      }

      final filename = picked.name.isNotEmpty
          ? picked.name
          : 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final titik = filename.lastIndexOf('.');
      final ext = titik >= 0 ? filename.substring(titik + 1).toLowerCase() : '';
      if (!_allowedExtensions.contains(ext)) {
        _showSnack('Format foto harus JPG, JPEG, PNG, atau WEBP.');
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) return;
      setState(
        () =>
            _photos.add(_PhotoItem.newLocal(bytes: bytes, filename: filename)),
      );
    } catch (_) {
      _showSnack('Gagal memilih foto. Coba lagi.');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_photos.isEmpty) {
      _showSnack('Silakan masukkan minimal 1 foto.');
      return;
    }

    final sedangMembuat = !_isEditing;

    final hargaNormal = _parseHarga(_hargaNormalController.text);
    if (hargaNormal == null || hargaNormal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga normal tidak valid.')),
      );
      return;
    }

    final hargaPromo = _parseHarga(_hargaPromoController.text);
    if (hargaPromo != null && hargaPromo > hargaNormal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harga promo tidak boleh lebih besar dari harga normal.',
          ),
        ),
      );
      return;
    }

    final tanggalMulai = _tanggalMulaiTersedia;
    final tanggalSelesai = _tanggalSelesaiTersedia;
    final periodeKosong = tanggalMulai == null && tanggalSelesai == null;

    if (!_isEditing && periodeKosong) {
      _showSnack('Tanggal mulai dan selesai ketersediaan wajib diisi.');
      return;
    }

    if (!periodeKosong && (tanggalMulai == null || tanggalSelesai == null)) {
      _showSnack('Lengkapi kedua tanggal periode atau kosongkan keduanya.');
      return;
    }

    if (_kategoriValue.trim().isEmpty) {
      _showSnack('Kategori tempat wajib diisi');
      return;
    }

    if (_kategoriValue.trim().length > 50) {
      _showSnack('Kategori maksimal 50 karakter');
      return;
    }

    if (tanggalMulai != null &&
        tanggalSelesai != null &&
        tanggalSelesai.isBefore(tanggalMulai)) {
      _showSnack(
        'Tanggal selesai ketersediaan tidak boleh sebelum tanggal mulai.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = ref.read(authNotifierProvider.select((s) => s.token));
      if (token == null) return;

      final fotoUrls = <String>[
        for (final photo in _photos)
          if (photo.url != null) photo.url!,
      ];

      for (final photo in _photos) {
        if (photo.bytes == null) continue;

        try {
          final result = await ref
              .read(uploadServiceProvider)
              .uploadPhoto(
                token: token,
                filename: photo.filename ?? 'foto.jpg',
                bytes: photo.bytes!,
              );
          fotoUrls.add(result.secureUrl);
        } catch (_) {
          _showSnack('Gagal mengunggah foto. Coba lagi.');
          return;
        }
      }

      final kategoriForSubmit = _kategoriValue;

      final payload = <String, dynamic>{
        'nama_tempat': _namaController.text.trim(),
        'kategori': kategoriForSubmit,
        'alamat': _alamatController.text.trim(),
        'kota': _kotaController.text.trim(),
        'harga_normal': hargaNormal,
        'tipe_durasi': _tipeDurasi,
        'deskripsi': _deskripsiController.text.trim(),
        'fasilitas': _fasilitasController.text.trim(),
        'aturan': _aturanController.text.trim(),
        'foto': fotoUrls,
        'tanggal_mulai_tersedia': tanggalMulai == null
            ? null
            : formatTanggalApi(tanggalMulai),
        'tanggal_selesai_tersedia': tanggalSelesai == null
            ? null
            : formatTanggalApi(tanggalSelesai),
        if (sedangMembuat)
          'harga_promo': ?hargaPromo
        else
          'harga_promo': hargaPromo,
      };

      final service = ref.read(placeServiceProvider);
      if (!sedangMembuat) {
        await service.updatePlace(
          token: token,
          id: _placeId!,
          payload: payload,
        );
      } else {
        final created = await service.createPlace(
          token: token,
          payload: payload,
        );

        if (!mounted) return;

        if (created.id.isNotEmpty) {
          setState(() {
            _placeId = created.id;
            _tanggalMulaiTersedia =
                created.tanggalMulaiTersedia ?? tanggalMulai;
            _tanggalSelesaiTersedia =
                created.tanggalSelesaiTersedia ?? tanggalSelesai;
            _photos
              ..clear()
              ..addAll(
                created.foto.map((url) => _PhotoItem.existing(url: url)),
              );
          });
        }
      }

      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();

      if (!mounted) return;

      if (!sedangMembuat) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tempat berhasil diperbarui')),
        );
        context.pop(true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tempat berhasil ditambahkan. Aturan ketersediaan sudah dapat '
            'diatur.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan tempat. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _namaController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama Tempat',
            hintText: 'Contoh: Lapak Kuliner Pasar Baru',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Nama tempat wajib diisi';
            if (text.length < 5) return 'Nama tempat minimal 5 karakter';
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
        if (_categoriesLoading)
          const _CategoryPickerSkeleton()
        else if (_categoriesError != null)
          _CategoryPickerError(onRetry: _loadCategories)
        else ...[
          CategoryPicker(
            categories: _categories,
            selected: _kategori,
            enabled: !_submitting,
            onChanged: (value) => setState(() => _kategori = value),
          ),
          if (_isKategoriCustom) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Kategori baru',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _kategoriLainController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kategori Lain',
                      hintText: 'Contoh: Warung Minuman',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    enabled: !_submitting,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Nama kategori lain wajib diisi';
                      if (text.length < 5) {
                        return 'Nama kategori minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nama ini akan dipakai sebagai kategori tempatmu.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _alamatController,
          decoration: const InputDecoration(
            labelText: 'Alamat',
            hintText: 'Contoh: Jl. Merdeka No. 10',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Alamat wajib diisi';
            if (text.length < 10) return 'Alamat minimal 10 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _kotaController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Kota',
            hintText: 'Contoh: Bandung',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Kota wajib diisi';
            if (text.length < 4) return 'Kota minimal 4 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _deskripsiController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Deskripsi',
            hintText: 'Contoh: Lapak makan malam dengan area parkir (min. 10 karakter)',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Deskripsi wajib diisi';
            if (text.length < 10) return 'Deskripsi minimal 10 karakter';
            if (text.length > 250) return 'Deskripsi maksimal 250 karakter';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoFields({bool withTitle = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withTitle) ...[
          const Text(
            'Foto Tempat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
        ],
        const Text(
          'Maks. 6 foto. Minimal 1 foto. Format JPG, JPEG, PNG, WEBP, maks 5 MB per foto.',
          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          const Text(
            'Silakan masukkan minimal 1 foto.',
            style: TextStyle(fontSize: 12, color: AppColors.danger),
          ),
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
              itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _photos.length) {
                  return _PhotoThumb(
                    photo: _photos[index],
                    onRemove: () => _removePhoto(index),
                  );
                }

                return _AddPhotoTile(onTap: _showPickSheet);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _fasilitasController,
          decoration: const InputDecoration(
            labelText: 'Fasilitas (opsional)',
            hintText: 'Pisahkan dengan koma, mis: Listrik, Kipas',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _aturanController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Aturan (opsional)',
            hintText: 'Mis: Tutup pukul 21.00',
          ),
        ),
      ],
    );
  }

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _hargaNormalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Normal (Rp)',
                  hintText: '250000',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Harga normal wajib diisi'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _hargaPromoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Promo (Rp)',
                  hintText: 'Kosong = tanpa promo',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Tipe Durasi',
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
                selected: _tipeDurasi == durasi,
                selectedColor: AppColors.primaryOrange,
                labelStyle: TextStyle(
                  color: _tipeDurasi == durasi
                      ? AppColors.white
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _tipeDurasi = durasi),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodFields({bool withTitle = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withTitle) ...[
          const Text(
            'Periode Ketersediaan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          _isEditing
              ? 'Tempat hanya dapat disewa dalam rentang tanggal ini. '
                    'Kosongkan kedua tanggal bila periode tidak dibatasi.'
              : 'Tempat hanya dapat disewa dalam rentang tanggal ini. '
                    'Kedua tanggal wajib diisi.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _tanggalMulaiController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Tanggal Mulai Tersedia',
            hintText: 'Pilih tanggal mulai',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pilihTanggalKetersediaan(mulai: true),
          validator: (_) {
            final mulaiKosong = _tanggalMulaiTersedia == null;
            final selesaiTerisi = _tanggalSelesaiTersedia != null;

            if (!_isEditing && mulaiKosong) {
              return 'Tanggal mulai tersedia wajib diisi';
            }
            if (mulaiKosong && selesaiTerisi) {
              return 'Lengkapi kedua tanggal atau kosongkan keduanya';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tanggalSelesaiController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Tanggal Selesai Tersedia',
            hintText: 'Pilih tanggal selesai',
            prefixIcon: Icon(Icons.event_available_outlined),
            helperText: 'Tidak boleh lebih awal dari tanggal mulai.',
          ),
          onTap: () => _pilihTanggalKetersediaan(mulai: false),
          validator: (_) {
            final selesaiKosong = _tanggalSelesaiTersedia == null;
            final mulaiTerisi = _tanggalMulaiTersedia != null;

            if (!_isEditing && selesaiKosong) {
              return 'Tanggal selesai tersedia wajib diisi';
            }
            if (selesaiKosong && mulaiTerisi) {
              return 'Lengkapi kedua tanggal atau kosongkan keduanya';
            }
            if (mulaiTerisi &&
                !selesaiKosong &&
                _tanggalSelesaiTersedia!.isBefore(_tanggalMulaiTersedia!)) {
              return 'Tidak boleh sebelum tanggal mulai';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilityFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvailabilityRuleSection(
          placeId: _placeId,
          periodeSelesai: _tanggalSelesaiTersedia,
        ),
      ],
    );
  }

  Widget _buildFormContent({required bool duaKolom}) {
    if (!duaKolom) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoFields(),
          const SizedBox(height: 16),
          _buildPhotoFields(),
          const SizedBox(height: 16),
          _buildDetailFields(),
          const SizedBox(height: 16),
          _buildPriceFields(),
          const SizedBox(height: 20),
          _buildPeriodFields(),
          const SizedBox(height: 20),
          _buildAvailabilityFields(),
          const SizedBox(height: 24),
        ],
      );
    }

    // Web: dua kolom. Kiri untuk informasi tempat dan fasilitas,
    // kanan untuk foto, harga, serta pengaturan ketersediaan.
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _FormSection(
                    title: 'Informasi Tempat',
                    icon: Icons.storefront_outlined,
                    child: _buildInfoFields(),
                  ),
                  const SizedBox(height: 20),
                  _FormSection(
                    title: 'Fasilitas & Aturan',
                    icon: Icons.rule_outlined,
                    child: _buildDetailFields(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _FormSection(
                    title: 'Foto Tempat',
                    icon: Icons.photo_library_outlined,
                    child: _buildPhotoFields(withTitle: false),
                  ),
                  const SizedBox(height: 20),
                  _FormSection(
                    title: 'Harga & Durasi',
                    icon: Icons.payments_outlined,
                    child: _buildPriceFields(),
                  ),
                  const SizedBox(height: 20),
                  _buildAvailabilityFields(),
                  const SizedBox(height: 20),
                  _FormSection(
                    title: 'Periode Ketersediaan',
                    icon: Icons.event_outlined,
                    child: _buildPeriodFields(withTitle: false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bolehMengelola =
        ref.watch(authNotifierProvider).user?.role == UserModel.roleHost;
    if (!bolehMengelola) {
      final page = Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const SpothAppBar(title: Text('Kelola Tempat')),
        body: const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Hanya pemilik yang dapat mengelola tempat',
              message:
                  'Fitur tambah dan ubah tempat usaha khusus untuk akun dengan '
                  'role Pemilik.',
            ),
          ),
        ),
      );

      return SpothSidebarScaffold(activeTab: MainTab.kelolaTempat, child: page);
    }

    final page = Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpothAppBar(
        title: Text(_isEditing ? 'Ubah Tempat' : 'Tambah Tempat'),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: PlaceFormSkeleton(),
            )
          : _loadError != null
          ? Center(
              child: EmptyState(
                icon: Icons.wifi_off,
                title: _loadError!,
                message: 'Periksa koneksi internet Anda lalu coba lagi.',
                actionLabel: 'Coba Lagi',
                onAction: _loadExisting,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final duaKolom = constraints.maxWidth >= 900;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: duaKolom ? AppWidth.page : AppWidth.form,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: _buildFormContent(duaKolom: duaKolom),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.softBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SafeArea(
                top: false,
                // heightFactor: 1 membuat tinggi bar mengikuti tombol,
                // bukan setinggi layar.
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppWidth.page),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final web = constraints.maxWidth >= 900;

                        return Row(
                          mainAxisAlignment: web
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: web ? 320 : constraints.maxWidth,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                child: Text(
                                  _submitting
                                      ? (_photos.any(
                                              (photo) => photo.bytes != null,
                                            )
                                            ? 'Mengunggah foto...'
                                            : 'Menyimpan...')
                                      : 'Simpan Tempat',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );

    return SpothSidebarScaffold(activeTab: MainTab.kelolaTempat, child: page);
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onRemove});

  final _PhotoItem photo;
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
              child: Icon(Icons.storefront, color: AppColors.primaryOrange),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 14, color: AppColors.white),
                ),
              ),
            ),
          ),
          if (photo.bytes != null)
            const Positioned(
              left: 4,
              bottom: 4,
              child: _MiniBadge(label: 'BARU'),
            ),
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
            Icon(Icons.add_a_photo_outlined, color: AppColors.primaryOrange),
            SizedBox(height: 6),
            Text(
              'Tambah Foto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _CategoryPickerSkeleton extends StatelessWidget {
  const _CategoryPickerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          ShimmerBox(width: 116, height: 38, radius: AppRadius.pill),
          ShimmerBox(width: 132, height: 38, radius: AppRadius.pill),
          ShimmerBox(width: 104, height: 38, radius: AppRadius.pill),
          ShimmerBox(width: 88, height: 38, radius: AppRadius.pill),
        ],
      ),
    );
  }
}

class _CategoryPickerError extends StatelessWidget {
  const _CategoryPickerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gagal memuat kategori. Periksa koneksi internet Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.lightOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
