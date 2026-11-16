import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.logoSize = 42});

  final double logoSize;

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
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'SPOTH UMKM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
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
              fontSize: 15,
              color: AppColors.secondaryText,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(const BorderSide(color: AppColors.neutralBorder)),
            enabledBorder: _border(
              const BorderSide(color: AppColors.neutralBorder),
            ),
            focusedBorder: _border(
              const BorderSide(color: AppColors.primaryOrange, width: 1.4),
            ),
            errorBorder: _border(BorderSide(color: errorColor)),
            focusedErrorBorder: _border(
              BorderSide(color: errorColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(BorderSide side) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.lightOrange : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : AppColors.neutralBorder,
              width: selected ? 1.3 : 1,
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
                    ? AppColors.primaryOrange
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
                            ? AppColors.primaryOrange
                            : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
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
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? AppColors.primaryOrange
                  : AppColors.secondaryText,
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
            const Icon(
              Icons.arrow_back,
              size: 18,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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

class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: errorColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
