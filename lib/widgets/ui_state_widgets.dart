import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';

class StateLoading extends StatelessWidget {
  final String message;
  const StateLoading({super.key, this.message = 'جار التحميل...'});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(message, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class StateEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CustomButton(text: actionLabel!, onPressed: onAction, height: 46),
            ],
          ],
        ),
      ),
    );
  }
}

class StateError extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onRetry;

  const StateError({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'إعادة المحاولة',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StateEmpty(
      icon: Icons.wifi_off_rounded,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onRetry,
    );
  }
}
