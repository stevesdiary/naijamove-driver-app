import 'package:flutter/material.dart';

/// Brand colour tokens from the NaijaMove Driver design spec
/// (driver_app_design_prompt.md). Shared palette with the Rider App plus
/// Earnings Green and the offline-toggle grey.
abstract final class AppColors {
  // Brand
  static const primaryBlue = Color(0xFF1A6FE8);
  static const primaryDark = Color(0xFF0A2D6E);
  static const primaryLight = Color(0xFFEBF2FD);
  static const accentGold = Color(0xFFF5A623);
  static const accentGoldTint = Color(0xFFFEF3C7);
  static const accentGoldText = Color(0xFF92400E);

  // Surfaces (light)
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF0F4FA);
  static const borderSubtle = Color(0xFFD1DCF0);

  // Text (light)
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF64748B);

  // Semantic
  static const dangerRed = Color(0xFFE53935);
  static const dangerTint = Color(0xFFFEE2E2);
  static const successTeal = Color(0xFF0EA5A0);
  static const successTint = Color(0xFFE6F7F6);
  static const earningsGreen = Color(0xFF16A34A);
  static const earningsTint = Color(0xFFE8F7EE);
  static const offlineGrey = Color(0xFF374151);
  static const nigeriaGreen = Color(0xFF008751);

  // Map
  static const mapWater = Color(0xFFDCE8F7);
  static const mapRoad = Color(0xFFD1DCF0);
  static const mapOverlay = Color(0x261A6FE8); // primaryBlue @ 15%
  static const surgeOverlay = Color(0x33F5A623); // accentGold @ 20%

  // Dark mode
  static const darkBackground = Color(0xFF0D1B2A);
  static const darkSurface = Color(0xFF1A2B40);
  static const darkBorder = Color(0xFF2A3F5F);
  static const darkTextPrimary = Color(0xFFF0F4FA);
  static const darkTextSecondary = Color(0xFF94A3B8);
}

/// Theme-aware accessors so screens don't hard-code light values.
extension AppColorScheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.darkBackground : AppColors.background;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get border => isDark ? AppColors.darkBorder : AppColors.borderSubtle;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get tint => isDark ? AppColors.darkBorder : AppColors.primaryLight;
}
