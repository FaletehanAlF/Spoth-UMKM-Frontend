import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRemembered() async {
    final rememberMe = await _storage.read(key: 'remember_me');

    if (rememberMe == 'true') {
      final email = await _storage.read(key: 'remembered_email');

      if (!mounted) return;
      setState(() {
        _rememberMe = true;
        _emailController.text = email ?? '';
      });
    } else {
      if (!mounted) return;
      setState(() => _rememberMe = false);
    }
  }

  Future<void> _persistRememberMe() async {
    if (_rememberMe) {
      await _storage.write(key: 'remember_me', value: 'true');
      await _storage.write(
        key: 'remembered_email',
        value: _emailController.text.trim(),
      );
    } else {
      await _storage.delete(key: 'remember_me');
      await _storage.delete(key: 'remembered_email');
    }
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      await _persistRememberMe();
      if (!mounted) return;
      context.go('/home');
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
            title: 'Selamat Datang Kembali',
            description: 'Masuk untuk melanjutkan ke akun SPOTH UMKM Anda.',
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  hintText: 'Masukkan password',
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: isLoading
                          ? null
                          : (value) =>
                                setState(() => _rememberMe = value ?? true),
                      activeColor: AppColors.primaryOrange,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: const WidgetStatePropertyAll<Color?>(
                        Colors.transparent,
                      ),
                      side: const BorderSide(
                        color: AppColors.neutralBorder,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: MouseRegion(
                        cursor: isLoading
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: isLoading
                              ? null
                              : () =>
                                    setState(() => _rememberMe = !_rememberMe),
                          child: const Text(
                            'Ingat saya',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AuthMessage(text: errorMessage),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Masuk',
                  isLoading: isLoading,
                  height: 52,
                  borderRadius: 14,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                AuthFooterLink(
                  label: 'Belum punya akun?',
                  actionLabel: 'Daftar',
                  enabled: !isLoading,
                  onTap: () => context.go('/register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
