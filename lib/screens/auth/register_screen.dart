import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _role;
  String? _roleError;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateNama(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama wajib diisi';
    if (text.length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(text)) return 'Format email tidak valid';
    if (text.length > 150) return 'Email maksimal 150 karakter';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    if (value.length > 72) return 'Password maksimal 72 karakter';
    return null;
  }

  void _selectRole(String role) {
    setState(() {
      _role = role;
      _roleError = null;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();

    if (_role == null) {
      setState(() => _roleError = 'Pilih salah satu peran');
    }

    if (!formValid || _role == null) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .register(
          nama: _namaController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role!,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Registrasi berhasil, silakan login'),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.errorMessage;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Buat Akun Baru',
            description:
                'Lengkapi data di bawah untuk mulai menggunakan SPOTH UMKM.',
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: 'Nama Lengkap',
                  controller: _namaController,
                  hintText: 'Nama sesuai identitas',
                  textInputAction: TextInputAction.next,
                  validator: _validateNama,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Password',
                  controller: _passwordController,
                  hintText: 'Minimal 8 karakter',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: _validatePassword,
                  enabled: !isLoading,
                  suffixIcon: AuthPasswordToggle(
                    hidden: _obscurePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Peran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AuthRoleOption(
                  title: 'Pemilik',
                  description: 'Untuk kamu yang ingin menyewakan tempat usaha.',
                  selected: _role == UserModel.roleHost,
                  onTap: () => _selectRole(UserModel.roleHost),
                ),
                const SizedBox(height: 10),
                AuthRoleOption(
                  title: 'Penyewa',
                  description: 'Untuk kamu yang mencari tempat usaha.',
                  selected: _role == UserModel.roleTenant,
                  onTap: () => _selectRole(UserModel.roleTenant),
                ),
                if (_roleError != null) ...[
                  const SizedBox(height: 8),
                  AuthMessage(text: _roleError!),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AuthMessage(text: errorMessage),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Daftar',
                  isLoading: isLoading,
                  height: 52,
                  borderRadius: 14,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                AuthFooterLink(
                  label: 'Sudah punya akun?',
                  actionLabel: 'Masuk',
                  enabled: !isLoading,
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
