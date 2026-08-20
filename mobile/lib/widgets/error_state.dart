import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown when a [FutureBuilder]/[AsyncSnapshot] genuinely errored (not just
/// "no data yet"), so a real failure never silently renders as an empty list.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message = 'Something went wrong loading this.', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppText.bodyMuted),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ],
      ),
    );
  }
}
