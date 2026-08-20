import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Eyebrow-style section title used above a group of cards or a list —
/// replaces the ad hoc `Text(..., style: TextStyle(letterSpacing: ...))`
/// that used to be repeated at every call site.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({super.key, required this.title, this.trailing, this.padding = const EdgeInsets.only(bottom: 10)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: AppText.eyebrow)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
