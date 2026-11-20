import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/permission_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/spoth_app_bar.dart';
import 'widgets/profile_account_card.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_summary_card.dart';

/// Halaman profil dengan dua mode:
/// 1. **Lihat** — data akun ditampilkan sebagai kartu read-only.
/// 2. **Edit** — aktif hanya setelah pengguna menekan tombol "Edit Profil".
///
/// Pemisahan ini membuat perubahan data tidak pernah terkirim tanpa
/// persetujuan pengguna dan menjaga tampilan tetap ringkas di layar kecil.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _emailController = TextEditingController();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  static const String _addressKey = 'profile_address';

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _fotoUrl;
  String _alamatTersimpan = '';

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final alamat = await _storage.read(key: _addressKey);
    if (!mounted) return;

    setState(() {
      _alamatTersimpan = alamat ?? '';
      _isiController(user, _alamatTersimpan);
      _fotoUrl = user.foto;
    });
  }

  void _isiController(UserModel user, String alamat) {
    _namaController.text = user.nama;
    _emailController.text = user.email;
    _noHpController.text = user.noHp ?? '';
    _alamatController.text = alamat;
  }

  Future<void> _mulaiEdit() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final alamat = await _storage.read(key: _addressKey) ?? _alamatTersimpan;
    if (!mounted) return;

    setState(() {
      _alamatTersimpan = alamat;
      _isiController(user, alamat);
      _fotoUrl = user.foto;
      _isEditing = true;
    });
  }

  void _batalEdit() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() {
      _isiController(user, _alamatTersimpan);
      _fotoUrl = user.foto;
      _isEditing = false;
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final alamat = _alamatController.text.trim();
    final berhasil = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(
          nama: _namaController.text.trim(),
          noHp: _noHpController.text.trim().isEmpty
              ? null
              : _noHpController.text.trim(),
          foto: _fotoUrl,
        );

    if (!mounted) return;

    if (berhasil) {
      await _storage.write(key: _addressKey, value: alamat);
      if (!mounted) return;

      setState(() {
        _alamatTersimpan = alamat;
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan.')),
      );
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil. Coba lagi.')),
      );
    }
  }

  Future<void> _pilihSumberFoto() async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.softBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganti foto profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primaryDeep,
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto baru'),
                onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryDeep,
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari penyimpanan'),
                onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (sumber == null) return;
    await _unggahFoto(sumber);
  }

  Future<void> _unggahFoto(ImageSource sumber) async {
    final token = ref.read(authNotifierProvider.select((state) => state.token));
    if (token == null) return;

    final diizinkan = sumber == ImageSource.camera
        ? await PermissionService.ensureCameraPermission()
        : await PermissionService.ensureGalleryPermission();

    if (!diizinkan) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sumber == ImageSource.camera
                ? 'Izin kamera tidak diizinkan.'
                : 'Izin galeri tidak diizinkan.',
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final picked = await _picker.pickImage(
        source: sumber,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (picked == null) return;

      final hasil = await ref
          .read(uploadServiceProvider)
          .uploadPhoto(
            token: token,
            filename: picked.name,
            bytes: await picked.readAsBytes(),
          );

      if (!mounted) return;

      setState(() => _fotoUrl = hasil.secureUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto siap. Tekan Simpan Perubahan untuk menerapkan.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah foto. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _hapusFoto() {
    setState(() => _fotoUrl = null);
  }

  Future<void> _logout() async {
    final yakin = await _konfirmasi('Keluar dari akun?');
    if (!mounted || !yakin) return;

    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<bool> _konfirmasi(String pesan) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const SpothAppBar(showRiwayat: true, showNotification: true),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Silakan login untuk melihat profil Anda.'),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final duaKolom = constraints.maxWidth >= AppWidth.twoColumn;

                final ringkasan = ProfileSummaryCard(
                  user: user,
                  fotoUrl: _fotoUrl,
                  isEditing: _isEditing,
                  isUploading: _isUploading,
                  onEdit: _mulaiEdit,
                  onGantiFoto: _pilihSumberFoto,
                  onHapusFoto: _hapusFoto,
                );

                final detail = _isEditing
                    ? ProfileEditForm(
                        formKey: _formKey,
                        namaController: _namaController,
                        emailController: _emailController,
                        noHpController: _noHpController,
                        alamatController: _alamatController,
                        isSaving: _isSaving,
                        onSave: _simpan,
                        onCancel: _batalEdit,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileInfoCard(user: user, alamat: _alamatTersimpan),
                          const SizedBox(height: 20),
                          ProfileAccountCard(onLogout: _logout),
                        ],
                      );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppWidth.page,
                      ),
                      child: duaKolom
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 320, child: ringkasan),
                                const SizedBox(width: 24),
                                Expanded(child: detail),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ringkasan,
                                const SizedBox(height: 20),
                                detail,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
