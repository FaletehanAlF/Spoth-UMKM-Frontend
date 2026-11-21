import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/app_layout.dart';

/// Bingkai halaman autentikasi.
///
/// Di layar lebar, formulir ditemani panel brand di sisi kiri supaya halaman
/// tidak terasa seperti kolom sempit yang mengambang di ruang kosong.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lebar = constraints.maxWidth >= 980;

            if (!lebar) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppWidth.auth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AuthBrand()),
                        const SizedBox(height: 30),
                        child,
                      ],
                    ),
                  ),
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: ClipPath(
                    clipper: const _AuthWaveClipper(),
                    child: _AuthBrandPanel(
                      availableHeight: constraints.maxHeight,
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Container(
                    color: AppColors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 56,
                        vertical: 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppWidth.auth,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({required this.availableHeight});

  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final tampilkanKartu = availableHeight >= 660;

    return Container(
      decoration: const BoxDecoration(color: AppColors.primaryDeep),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(56, 44, 96, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthBrand(logoSize: 38, textColor: AppColors.white),
            const SizedBox(height: 56),
            Text(
              'Ruang kecil,\nusaha besar.',
              style: AppFonts.heading(
                fontSize: 46,
                weight: 700,
                height: 1.04,
                letterSpacing: -1.6,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const Text(
                'SPOTH UMKM mempertemukan pemilik lapak, teras, dan booth '
                'dengan orang-orang yang siap memulai usahanya.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BrandTag(
                  icon: Icons.storefront_outlined,
                  label: 'Lapak usaha',
                ),
                _BrandTag(icon: Icons.deck_outlined, label: 'Teras komersial'),
                _BrandTag(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booth event',
                ),
              ],
            ),
            if (tampilkanKartu) ...[
              const SizedBox(height: 36),
              const _AuthPlacePreview(),
            ],
            const SizedBox(height: 36),
            Text(
              '“Tumbuh bersama UMKM Indonesia”',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandTag extends StatelessWidget {
  const _BrandTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPlacePreview extends StatelessWidget {
  const _AuthPlacePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.storefront,
              color: AppColors.primaryDeep,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lapak Kuliner',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bandung Â· 2 menit dari pasar',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rp200.000 / hari',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.logoSize = 42, this.textColor = AppColors.charcoal});

  final double logoSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: Image.asset(
            'assets/icons/spoth-umkm-logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.storefront,
              size: logoSize,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'SPOTH UMKM',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.description,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String description;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final centered = textAlign == TextAlign.center;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: AppFonts.heading(
            fontSize: 27,
            weight: 700,
            height: 1.18,
            letterSpacing: -0.7,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 14,
            height: 1.55,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autocorrect = true,
    this.inputFormatters,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          autocorrect: autocorrect,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15, color: AppColors.darkText),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14.5,
              color: AppColors.secondaryText,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(const BorderSide(color: AppColors.neutralBorder)),
            enabledBorder: _border(
              const BorderSide(color: AppColors.neutralBorder),
            ),
            focusedBorder: _border(
              const BorderSide(color: AppColors.primaryDeep, width: 1.6),
            ),
            errorBorder: _border(BorderSide(color: errorColor)),
            focusedErrorBorder: _border(
              BorderSide(color: errorColor, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(BorderSide side) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: side,
    );
  }
}

class AuthRoleOption extends StatelessWidget {
  const AuthRoleOption({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.lightOrange : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primaryDeep : AppColors.neutralBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? AppColors.primaryDeep
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryInk
                            : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.hidden,
    required this.onPressed,
  });

  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: IconButton.styleFrom(overlayColor: Colors.transparent),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.secondaryText,
      ),
      tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
      onPressed: onPressed,
    );
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: enabled ? AppColors.primaryInk : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.label,
    required this.actionLabel,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
        ),
        AuthTextLink(
          label: actionLabel,
          fontSize: 14,
          enabled: enabled,
          onTap: onTap,
        ),
      ],
    );
  }
}

class AuthBackLink extends StatelessWidget {
  const AuthBackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: AppColors.primaryInk),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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

class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AuthWaveClipper extends CustomClipper<Path> {
  const _AuthWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.cubicTo(
      size.width * 0.86,
      size.height * 0.28,
      size.width * 0.86,
      size.height * 0.72,
      size.width,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _AuthWaveClipper oldClipper) => false;
}
