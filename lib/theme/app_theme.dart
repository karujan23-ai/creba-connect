import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The custom light and dark themes. Both are built by the same function
/// from a palette, so they always stay in step with each other.
class AppTheme {
  AppTheme._();

  static const _sans = 'Inter';
  static const _serif = 'InstrumentSerif';

  static final ThemeData lightTheme = _build(AppPalette.light, Brightness.light);
  static final ThemeData darkTheme = _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final textTheme = _textTheme(p);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: p.border),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _sans,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: p.text.withValues(alpha: 0.05),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.accent,
        onSecondary: Colors.white,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.text,
        onSurfaceVariant: p.textMuted,
        outline: p.border,
        outlineVariant: p.border,
        surfaceContainerHighest: p.surfaceAlt,
        surfaceTint: Colors.transparent,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: textTheme.bodyLarge?.copyWith(color: p.textFaint),
        labelStyle: textTheme.bodyLarge?.copyWith(color: p.textMuted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: p.danger),
        errorMaxLines: 2,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: p.text, width: 1.2),
        ),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: p.danger, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.textFaint,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: p.border),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.text,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      iconTheme: IconThemeData(color: p.text, size: 22),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.background),
        shape: buttonShape,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.text,
        unselectedLabelColor: p.textMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: p.text,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onPrimary : p.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.surfaceAlt,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.text,
        linearTrackColor: p.surfaceAlt,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: p.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textMuted,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
    );
  }

  /// Serif for the few large headings (an editorial feel), Inter for
  /// everything else.
  static TextTheme _textTheme(AppPalette p) {
    TextStyle serif(double size) => TextStyle(
          fontFamily: _serif,
          fontSize: size,
          height: 1.12,
          letterSpacing: -0.3,
          color: p.text,
        );
    TextStyle sans(double size, FontWeight weight, {double height = 1.4, Color? color}) =>
        TextStyle(
          fontFamily: _sans,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? p.text,
        );

    return TextTheme(
      displaySmall: serif(38),
      headlineLarge: serif(32),
      headlineMedium: serif(27),
      headlineSmall: serif(23),
      titleLarge: sans(18, FontWeight.w600, height: 1.25).copyWith(letterSpacing: -0.2),
      titleMedium: sans(15.5, FontWeight.w600, height: 1.3),
      titleSmall: sans(14, FontWeight.w600, height: 1.3),
      bodyLarge: sans(15.5, FontWeight.w400, height: 1.5),
      bodyMedium: sans(14, FontWeight.w400, height: 1.5),
      bodySmall: sans(12.5, FontWeight.w400, color: p.textMuted),
      labelLarge: sans(14.5, FontWeight.w600, height: 1.2),
      labelMedium: sans(12.5, FontWeight.w500, height: 1.2),
      labelSmall: sans(11, FontWeight.w600, height: 1.2, color: p.textMuted)
          .copyWith(letterSpacing: 0.9),
    );
  }
}
