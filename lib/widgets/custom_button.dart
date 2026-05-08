import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final bool loading;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors,
    this.loading = false,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final useGradient = gradientColors ?? colors.primaryGradient;
    final isDisabled = loading || onPressed == null;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isDisabled
              ? LinearGradient(
                  colors: [colors.muted.withValues(alpha: 0.6), colors.muted],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: useGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: isDisabled
              ? const []
              : [
                  BoxShadow(
                    color: useGradient.first.withValues(alpha: 0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
