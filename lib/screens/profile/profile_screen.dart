import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/riwayat_icon_button.dart';
import '../../widgets/spoth_app_bar.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final address = await _storage.read(key: _addressKey);
    if (!mounted) return;

    setState(() {
      _namaController.text = user.nama;
      _emailController.text = user.email;
      _noHpController.text = user.noHp ?? '';
      _alamatController.text = address ?? '';
    });
  }

  Future<void> _onFotoGaleri() async {
    final token = ref.watch(authNotifierProvider.select((s) => s.token));
    if (token == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (picked == null) return;

      final result = await ref
          .read(uploadServiceProvider)
          .uploadPhoto(
            token: token,
            filename: picked.name,
            bytes: await picked.readAsBytes(),
          );

      if (!mounted) return;

      setState(() => _fotoUrl = result.secureUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diupload.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunggah foto. Coba lagi.'),
        ),
      );
    }
  }

  String? _fotoUrl;

  Future<void> _onHapusFoto() async {
    final confirmed = await _confirm(
      context,
      'Hapus foto? Foto akan kembali ke foto akun.',
    );
    if (!confirmed || !mounted) return;
    setState(() => _fotoUrl = null);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final ok = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(
          nama: _namaController.text.trim(),
          noHp: _noHpController.text.trim().isEmpty
              ? null
              : _noHpController.text.trim(),
          foto: _fotoUrl,
        );

    if (!mounted) return;

    await _storage.write(
      key: _addressKey,
      value: _alamatController.text.trim(),
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan.')),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(message),
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
    return result ?? false;
  }

  Future<void> _logout() async {
    final confirmed = await _confirm(context, 'Keluar dari akun?');
    if (!mounted) return;
    if (!confirmed) return;

    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go('/login');
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
      appBar: SpothAppBar(
        title: const Text('Spoth UMKKM'),
        centerTitle: true,
        actions: const [NotificationIconButton(), RiwayatIconButton()],
      ),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Silakan login untuk melihat profil Anda.'),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoCard(
                        fotoUrl: _fotoUrl,
                        user: user,
                        onGaleri: _onFotoGaleri,
                        onHapus: _onHapusFoto,
                      ),
                      const SizedBox(height: 20),
                      _EditCard(
                        formKey: _formKey,
                        namaController: _namaController,
                        emailController: _emailController,
                        noHpController: _noHpController,
                        alamatController: _alamatController,
                        user: user,
                        onSave: _onSave,
                        isSaving: _isSaving,
                      ),
                      const SizedBox(height: 20),
                      _AccountCard(onLogout: _logout),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.fotoUrl,
    required this.user,
    required this.onGaleri,
    required this.onHapus,
  });

  final String? fotoUrl;
  final UserModel user;
  final VoidCallback onGaleri;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final initial = user.nama.trim().isNotEmpty
        ? user.nama.trim()[0].toUpperCase()
        : 'S';

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.lightOrange,
                backgroundImage: fotoUrl == null ? null : NetworkImage(fotoUrl!),
                child: fotoUrl == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primaryDeep,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppColors.primaryDeep,
                  shape: const CircleBorder(),
                  child: InkResponse(
                    onTap: onGaleri,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fotoUrl == null ? 'Tap untuk ambil dari galeri' : 'Foto aktif',
            style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Hapus foto'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({
    required this.formKey,
    required this.namaController,
    required this.emailController,
    required this.noHpController,
    required this.alamatController,
    required this.user,
    required this.onSave,
    required this.isSaving,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController namaController;
  final TextEditingController emailController;
  final TextEditingController noHpController;
  final TextEditingController alamatController;
  final UserModel user;
  final VoidCallback onSave;
  final bool isSaving;

  static const String _exampleAlamat =
      'Jalan Sudirman No. 45, Buahbatu, Bandung';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profil',
                style: AppFonts.heading(
                  fontSize: 17,
                  weight: 700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaController,
                enabled: !isSaving,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Nama wajib diisi'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: noHpController,
                enabled: !isSaving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon (Opsional)',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: alamatController,
                enabled: !isSaving,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onTap: () {
                  if (alamatController.text.trim().isEmpty) {
                    alamatController.text = _exampleAlamat;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Alamat (Kamu bisa isi sendiri)',
                  hintText: _exampleAlamat,
                  prefixIcon: const Icon(Icons.home_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: user.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Simpan Profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Akun',
              style: AppFonts.heading(
                fontSize: 15,
                weight: 700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amankan akunmu, keluarkan dari perangkat ini jika perlu.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
