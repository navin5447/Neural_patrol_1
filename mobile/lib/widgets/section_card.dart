import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;
  final Color? accent;

  const SectionCard({
    super.key,
    this.title,
    this.titleIcon,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.trailing,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: accent != null
            ? [BoxShadow(color: accent!.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: -6)]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, size: 15, color: accent ?? AppColors.textMuted),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: Text(title!.toUpperCase(), style: AppText.eyebrow)),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
