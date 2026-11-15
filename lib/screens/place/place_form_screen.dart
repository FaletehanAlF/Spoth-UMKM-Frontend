import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/place_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/place_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';

/// Form tambah/ubah tempat usaha untuk Pemilik (HOST).
///
/// - Tanpa `placeId` → `POST /places` (tambah; status default AKTIF di backend).
/// - Dengan `placeId` → memuat data lalu `PATCH /places/:id` (ubah;
///   status ikut dikelola lewat switch).
///
/// Foto belum diintegrasikan (opsional di backend) — pekerjaan menyusul.
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

  String _kategori = PlaceModel.kategoriValues.first;
  String _tipeDurasi = PlaceModel.durasiValues.first;
  bool _statusAktif = true;
  bool _loading = false;
  bool _submitting = false;
  String? _loadError;

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

      final payload = <String, dynamic>{
        'nama_tempat': _namaController.text.trim(),
        'kategori': _kategori,
        'alamat': _alamatController.text.trim(),
        'kota': _kotaController.text.trim(),
        'harga_normal': hargaNormal,
        'tipe_durasi': _tipeDurasi,
        if (_deskripsiController.text.trim().isNotEmpty)
          'deskripsi': _deskripsiController.text.trim(),
        // Fasilitas dikirim sebagai string (boleh kosong) agar daftar
        // fasilitas dapat dikosongkan; meng-omit key akan mempertahankan
        // nilai lama di backend.
        'fasilitas': _fasilitasController.text.trim(),
        if (_aturanController.text.trim().isNotEmpty)
          'aturan': _aturanController.text.trim(),
        // Saat mengedit: kirim eksplisit (termasuk null) agar promo dapat
        // dihapus — skema update backend menerima `harga_promo: null`.
        // Saat menambah: null di-omit (`?`) karena skema create backend
        // tidak menerima null (hanya angka positif atau key tidak dikirim).
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
    // Pembatasan akses: hanya Pemilik (HOST) yang boleh mengelola tempat.
    // Penyewa tidak dapat menambah/mengubah tempat usaha.
    final bolehMengelola =
        ref.watch(authNotifierProvider).user?.role == UserModel.roleHost;
    if (!bolehMengelola) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(title: const Text('Kelola Tempat')),
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
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: Text(_isEditing ? 'Ubah Tempat' : 'Tambah Tempat')),
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
          : Form(
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
                    child: Text(_submitting ? 'Menyimpan...' : 'Simpan Tempat'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
