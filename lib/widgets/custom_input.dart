import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomInput extends StatelessWidget {
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final bool showPassword;
  final VoidCallback? onTogglePassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final String? errorText;
  final TextDirection? textDirection;

  const CustomInput({
    super.key,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    this.showPassword = false,
    this.onTogglePassword,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && !showPassword,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      textDirection: textDirection,
      style: TextStyle(
        color: colors.text,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        errorText: errorText,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 22,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
    );
  }
}
