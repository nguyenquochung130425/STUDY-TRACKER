import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
    this.isPrimary = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;
  final bool isPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final button = isPrimary
        ? FilledButton.icon(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              backgroundColor: AppColors.primary,
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon ?? const SizedBox.shrink(),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon ?? const SizedBox.shrink(),
            label: Text(label),
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
