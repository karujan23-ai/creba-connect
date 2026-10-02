import 'package:flutter/material.dart';

/// The app's colours. There is one set for light mode and one for dark mode;
/// widgets read whichever is active through `context.palette`, so no screen
/// ever hard-codes a colour.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.verified,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Page background.
  final Color background;

  /// Cards, sheets and input fields.
  final Color surface;

  /// Chips, avatars and other quiet fills.
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;

  /// Main buttons. Ink-black in light mode, off-white in dark mode.
  final Color primary;
  final Color onPrimary;

  /// The single accent colour, used sparingly (match score, promoted).
  final Color accent;
  final Color verified;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = AppPalette(
    background: Color(0xFFF7F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0EEE9),
    border: Color(0xFFE5E2DB),
    text: Color(0xFF161616),
    textMuted: Color(0xFF6B6862),
    textFaint: Color(0xFF9D9992),
    primary: Color(0xFF161616),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFC2543A),
    verified: Color(0xFF2563EB),
    success: Color(0xFF1F7A52),
    warning: Color(0xFFA86A12),
    danger: Color(0xFFC0392B),
  );

  static const dark = AppPalette(
    background: Color(0xFF0F0F10),
    surface: Color(0xFF18181A),
    surfaceAlt: Color(0xFF222225),
    border: Color(0xFF2C2C30),
    text: Color(0xFFF4F2EE),
    textMuted: Color(0xFFA5A29C),
    textFaint: Color(0xFF75726D),
    primary: Color(0xFFF4F2EE),
    onPrimary: Color(0xFF161616),
    accent: Color(0xFFE5826A),
    verified: Color(0xFF7AA7FF),
    success: Color(0xFF55C794),
    warning: Color(0xFFE2AE55),
    danger: Color(0xFFF08A7E),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      border: mix(border, other.border),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      accent: mix(accent, other.accent),
      verified: mix(verified, other.verified),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
    );
  }
}

/// Shortcuts so widgets can write `context.palette` and `context.textTheme`.
extension ThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

/// Spacing and corner sizes used everywhere, so the app looks consistent.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Space between the screen edge and content.
  static const double page = 20;

  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusLg = 16;
}
