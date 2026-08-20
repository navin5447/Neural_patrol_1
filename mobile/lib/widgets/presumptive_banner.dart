import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The recurring legal/operational disclaimer: a field result is a
/// screening signal only, never a final forensic or legal conclusion.
class PresumptiveBanner extends StatelessWidget {
  final bool invalid;

  const PresumptiveBanner({super.key, this.invalid = false});

  @override
  Widget build(BuildContext context) {
    final color = invalid ? AppColors.danger : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(invalid ? Icons.block : Icons.info_outline, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invalid ? 'INVALID TEST' : 'PRESUMPTIVE FIELD RESULT ONLY',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
                const SizedBox(height: 2),
                Text(
                  invalid
                      ? 'Control line not detected — discard this run and repeat using the approved workflow.'
                      : 'Not a final forensic or legal conclusion. Confirmatory testing by the authorized FSL is required.',
                  style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
