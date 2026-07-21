import 'package:flutter/material.dart';

class AppColors {
  // ── Dark palette ───────────────────────────────────────────────────────────
  static const darkBg   = Color(0xFF0F0D1A);
  static const darkBg2  = Color(0xFF16122B);
  static const darkCard = Color(0xFF1B1830);
  static const darkTrack = Color(0xFF2B2844);
  static const darkTextPrimary   = Color(0xFFF5F4FA);
  static const darkTextSecondary = Color(0xFF8E8BA3);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const lightBg   = Color(0xFFF0EFF8);
  static const lightBg2  = Color(0xFFE4E2F2);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightTrack = Color(0xFFE2E0EF);
  static const lightTextPrimary   = Color(0xFF1A1830);
  static const lightTextSecondary = Color(0xFF6B6880);

  // ── Accent (shared) ────────────────────────────────────────────────────────
  static const purple      = Color(0xFF8C7BFF);
  static const lightPurple = Color(0xFFB6A6FF);
  static const deepBlue    = Color(0xFF5B8DEF);
  static const remGreen    = Color(0xFF45D6A6);
  static const yellow      = Color(0xFFF5C84C);
  static const red         = Color(0xFFFF6B6B);
}

/// Convenience extension so widgets can write `context.cardColor` etc.
extension AppThemeX on BuildContext {
  bool   get isDark         => Theme.of(this).brightness == Brightness.dark;
  Color  get bgColor        => isDark ? AppColors.darkBg        : AppColors.lightBg;
  Color  get bg2Color       => isDark ? AppColors.darkBg2       : AppColors.lightBg2;
  Color  get cardColor      => isDark ? AppColors.darkCard      : AppColors.lightCard;
  Color  get trackColor     => isDark ? AppColors.darkTrack     : AppColors.lightTrack;
  Color  get textPrimary    => isDark ? AppColors.darkTextPrimary    : AppColors.lightTextPrimary;
  Color  get textSecondary  => isDark ? AppColors.darkTextSecondary  : AppColors.lightTextSecondary;
}