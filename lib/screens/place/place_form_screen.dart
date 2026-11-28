import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/spoth_app_bar.dart';
import '../../widgets/spoth_sidebar_scaffold.dart';
import 'place_form/place_fields.dart';
import 'place_form/place_form_controller.dart';

class PlaceFormScreen extends ConsumerStatefulWidget {
  const PlaceFormScreen({super.key, this.placeId});

  final String? placeId;

  @override
  ConsumerState<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends ConsumerState<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PlaceFormController _form;

  @override
  void initState() {
    super.initState();
    _form = PlaceFormController(ref: ref, placeId: widget.placeId);
    _form.init();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _pesan('Lengkapi data yang ditandai merah.');
      return;
    }

    final hasil = await _form.simpan();
    _pesan(hasil.pesan);

    if (hasil.berhasil && mounted) {
      context.pop(true);
    }
  }

  Future<void> _pilihFoto() async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
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
                      color: AppColors.charcoal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_form.photos.length}/${PlaceFormController.maxPhotos}',
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
                color: AppColors.primaryDeep,
              ),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primaryDeep,
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (sumber == null) return;

    final error = await _form.tambahFoto(sumber);
    if (error != null) _pesan(error);
  }

  Widget _formFields({required bool duaKolom}) {
    final foto = FormSection(
      title: 'Foto Tempat',
      child: PhotoFields(
        photos: _form.photos,
        maxPhotos: PlaceFormController.maxPhotos,
        onAdd: _pilihFoto,
        onRemove: (index) => _form.hapusFoto(index),
      ),
    );

    final info = FormSection(
      title: 'Informasi Tempat',
      child: InfoFields(
        namaController: _form.namaController,
        alamatController: _form.alamatController,
        deskripsiController: _form.deskripsiController,
        kategoriLainController: _form.kategoriLainController,
        kategori: _form.kategori,
        onKategoriChanged: _form.setKategori,
        kecamatan: _form.kecamatan,
        onKecamatanChanged: _form.setKecamatan,
        categories: _form.categories,
        categoriesLoading: _form.categoriesLoading,
        categoriesError: _form.categoriesError,
        onRetryCategories: _form.init,
        enabled: !_form.submitting,
      ),
    );

    final harga = FormSection(
      title: 'Harga Sewa',
      child: PriceDurationFields(
        paketMingguan: _form.paketMingguan,
        paketBulanan: _form.paketBulanan,
        hargaMingguanController: _form.hargaMingguanController,
        hargaBulananController: _form.hargaBulananController,
        onPaketMingguanChanged: _form.setPaketMingguan,
        onPaketBulananChanged: _form.setPaketBulanan,
        enabled: !_form.submitting,
      ),
    );

    final lokasi = FormSection(
      title: 'Lokasi',
      child: LokasiFields(
        latitude: _form.latitude,
        longitude: _form.longitude,
        membacaLokasi: _form.membacaLokasi,
        onGunakanLokasiSaatIni: () async {
          final pesan = await _form.gunakanLokasiSaatIni();
          _pesan(pesan ?? 'Lokasi saat ini ditambahkan.');
        },
        onCariKoordinatDariAlamat: () async {
          final pesan = await _form.cariKoordinatDariAlamat();
          _pesan(pesan ?? 'Koordinat dari alamat ditambahkan.');
        },
        onHapusLokasi: _form.hapusLokasi,
        onKoordinatDipilih: _form.setKoordinat,
        enabled: !_form.submitting,
      ),
    );

    if (!duaKolom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foto,
          const SizedBox(height: 24),
          info,
          const SizedBox(height: 24),
          lokasi,
          const SizedBox(height: 24),
          harga,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [foto, const SizedBox(height: 24), harga],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [info, const SizedBox(height: 24), lokasi],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bolehMengelola =
        ref.watch(authNotifierProvider).user?.role == UserModel.roleHost;

    if (!bolehMengelola) {
      return SpothSidebarScaffold(
        activeTab: MainTab.kelolaTempat,
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: const SpothAppBar(title: Text('Kelola')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.lock_outline,
                title: 'Khusus pemilik tempat',
                message:
                    'Fitur tambah dan ubah tempat khusus akun dengan role '
                    'Pemilik.',
              ),
            ),
          ),
        ),
      );
    }

    return SpothSidebarScaffold(
      activeTab: MainTab.kelolaTempat,
      child: AnimatedBuilder(
        animation: _form,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: SpothAppBar(
              title: Text(_form.isEditing ? 'Ubah Tempat' : 'Tambah Tempat'),
            ),
            body: _form.loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: PlaceFormSkeleton(),
                  )
                : _form.loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.wifi_off,
                        title: _form.loadError!,
                        message: 'Periksa koneksi lalu coba lagi.',
                        actionLabel: 'Coba lagi',
                        onAction: _form.init,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final duaKolom =
                          MediaQuery.sizeOf(context).width >= AppWidth.sidebar;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: duaKolom
                                ? AppWidth.page
                                : AppWidth.form,
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                duaKolom ? 24 : 16,
                                8,
                                duaKolom ? 24 : 16,
                                96,
                              ),
                              children: [_formFields(duaKolom: duaKolom)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            bottomNavigationBar: _form.loading || _form.loadError != null
                ? null
                : _BarSimpan(
                    sedangMenyimpan: _form.submitting,
                    onSimpan: _simpan,
                  ),
          );
        },
      ),
    );
  }
}

class _BarSimpan extends StatelessWidget {
  const _BarSimpan({required this.sedangMenyimpan, required this.onSimpan});

  final bool sedangMenyimpan;
  final VoidCallback onSimpan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppWidth.form),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: sedangMenyimpan ? null : onSimpan,
                child: Text(
                  sedangMenyimpan
                      ? 'Menyimpan...'
                      : 'Simpan Tempat',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
