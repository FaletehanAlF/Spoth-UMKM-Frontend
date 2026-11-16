import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/place_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/place_provider.dart';
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

  static const int _maxPhotos = 6;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  String _kategori = PlaceModel.kategoriValues.first;
  String _tipeDurasi = PlaceModel.durasiValues.first;
  bool _statusAktif = true;
  bool _loading = false;
  bool _submitting = false;
  String? _loadError;

  final List<_PhotoItem> _photos = [];
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => (widget.placeId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    }
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
          .getPlaceDetail(id: widget.placeId!, token: token);

      if (!mounted) return;
      _namaController.text = place.namaTempat;
      _deskripsiController.text = place.deskripsi ?? '';
      _alamatController.text = place.alamat;
      _kotaController.text = place.kota;
      _fasilitasController.text = (place.fasilitas ?? '').trim();
      _aturanController.text = place.aturan ?? '';
      _hargaNormalController.text = _trimNumber(place.hargaNormal);
      _hargaPromoController.text = place.hargaPromo == null
          ? ''
          : _trimNumber(place.hargaPromo!);
      _kategori = place.kategori;
      _tipeDurasi = place.tipeDurasi;
      _statusAktif = place.isAktif;
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

      final payload = <String, dynamic>{
        'nama_tempat': _namaController.text.trim(),
        'kategori': _kategori,
        'alamat': _alamatController.text.trim(),
        'kota': _kotaController.text.trim(),
        'harga_normal': hargaNormal,
        'tipe_durasi': _tipeDurasi,
        if (_deskripsiController.text.trim().isNotEmpty)
          'deskripsi': _deskripsiController.text.trim(),
        'fasilitas': _fasilitasController.text.trim(),
        if (_aturanController.text.trim().isNotEmpty)
          'aturan': _aturanController.text.trim(),
        'foto': fotoUrls,
        if (_isEditing)
          'harga_promo': hargaPromo
        else
          'harga_promo': ?hargaPromo,
        if (_isEditing) 'status': _statusAktif ? 'AKTIF' : 'NONAKTIF',
      };

      final service = ref.read(placeServiceProvider);
      if (_isEditing) {
        await service.updatePlace(
          token: token,
          id: widget.placeId!,
          payload: payload,
        );
      } else {
        await service.createPlace(token: token, payload: payload);
      }

      await ref.read(myPlacesProvider.notifier).refresh();
      await ref.read(hostSummaryProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Tempat berhasil diperbarui'
                : 'Tempat berhasil ditambahkan',
          ),
        ),
      );
      context.pop(true);
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

  @override
  Widget build(BuildContext context) {
    final bolehMengelola =
        ref.watch(authNotifierProvider).user?.role == UserModel.roleHost;
    if (!bolehMengelola) {
      final page = Scaffold(
        backgroundColor: AppColors.white,
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

      return SpothSidebarScaffold(child: page);
    }

    final page = Scaffold(
      backgroundColor: AppColors.white,
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
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextFormField(
                        controller: _namaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama Tempat',
                          hintText: 'Contoh: Lapak Kuliner Pasar Baru',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Nama tempat wajib diisi'
                            : null,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kategori in PlaceModel.kategoriValues)
                            ChoiceChip(
                              label: Text(
                                PlaceModel.kategoriLabels[kategori] ?? kategori,
                              ),
                              selected: _kategori == kategori,
                              selectedColor: AppColors.primaryOrange,
                              labelStyle: TextStyle(
                                color: _kategori == kategori
                                    ? AppColors.white
                                    : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _kategori = kategori),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _alamatController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Alamat wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kotaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Kota'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Kota wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (opsional)',
                          hintText: 'Jelaskan tempat usaha Anda',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Foto Tempat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Maks. 6 foto. Format JPG, JPEG, PNG, WEBP, maks 5 MB per foto.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            _PhotoThumb(
                              photo: _photos[i],
                              onRemove: () => _removePhoto(i),
                            ),
                          if (_photos.length < _maxPhotos)
                            _AddPhotoTile(onTap: _showPickSheet),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
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
                              label: Text(
                                PlaceModel.durasiLabels[durasi] ?? durasi,
                              ),
                              selected: _tipeDurasi == durasi,
                              selectedColor: AppColors.primaryOrange,
                              labelStyle: TextStyle(
                                color: _tipeDurasi == durasi
                                    ? AppColors.white
                                    : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _tipeDurasi = durasi),
                            ),
                        ],
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.primaryOrange,
                          title: const Text(
                            'Tempat Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          subtitle: const Text(
                            'Tempat nonaktif tidak tampil kepada penyewa',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          value: _statusAktif,
                          onChanged: (value) =>
                              setState(() => _statusAktif = value),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting
                              ? (_photos.any((photo) => photo.bytes != null)
                                    ? 'Mengunggah foto...'
                                    : 'Menyimpan...')
                              : 'Simpan Tempat',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );

    return SpothSidebarScaffold(child: page);
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
