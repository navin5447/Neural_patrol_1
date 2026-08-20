import 'package:flutter/material.dart';

/// Full color system. Kept as a flat set of named constants (rather than a
/// ColorScheme extension) so every screen can reach for a semantic name —
/// `AppColors.success`, `AppColors.textMuted` — without threading BuildContext
/// through helpers just to read a color.
class AppColors {
  AppColors._();

  // Surfaces — each one step lighter than the last, so depth reads clearly
  // without relying on shadows (which barely show on a near-black base).
  static const background = Color(0xFF060B12);
  static const surface = Color(0xFF0D1520);
  static const surfaceRaised = Color(0xFF141F2D);
  static const surfaceHighlight = Color(0xFF1B2836);

  static const border = Color(0x1FFFFFFF);
  static const borderStrong = Color(0x3DFFFFFF);

  // Brand — amber stays the primary action/identity color; teal is the
  // secondary accent used for informational / in-progress states so the
  // whole UI doesn't read as one flat wash of yellow.
  static const accent = Color(0xFFFFC93C);
  static const accentDeep = Color(0xFFE8A93B);
  static const accentOn = Color(0xFF1A1300);
  static const teal = Color(0xFF3FD3C6);

  static const textPrimary = Color(0xFFF3F7FB);
  static const textSecondary = Color(0xFFAAB9CB);
  static const textMuted = Color(0xFF71829A);

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFF9F43);
  static const danger = Color(0xFFF0546B);
  static const info = Color(0xFF4FB6FF);

  /// Species-panel severity accents used on the field-result report card —
  /// distinct from the general semantic set above so a "Human" escalation
  /// reads unmistakably differently from a routine species indication.
  static const escalation = Color(0xFFFF5D6C);
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const pill = 999.0;
}

/// Typography scale. Everything routes through here instead of ad hoc
/// `TextStyle(...)` literals so weight/spacing stays consistent across 30+
/// screens and widgets.
class AppText {
  AppText._();

  static const eyebrow = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  static const h1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const h2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const h3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const body = TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4);
  static const bodyStrong = TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, height: 1.4);
  static const bodyMuted = TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4);
  static const caption = TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.3);
  static const label = TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3);

  static const mono = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontFamily: 'monospace',
    letterSpacing: 0.2,
  );

  static const statValue = TextStyle(
    color: AppColors.accent,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.0,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: AppColors.accentOn,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h3,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentOn,
          disabledBackgroundColor: AppColors.surfaceHighlight,
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 13.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4, fontSize: 13.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        contentTextStyle: AppText.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: AppText.h3,
        contentTextStyle: AppText.bodyMuted,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
    );
  }
}
