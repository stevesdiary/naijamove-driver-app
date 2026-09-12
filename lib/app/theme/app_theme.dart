import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

const kFontFamily = 'Inter';

TextStyle _inter({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  List<FontFeature>? fontFeatures,
}) => TextStyle(
  fontFamily: kFontFamily,
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  fontFeatures: fontFeatures,
);

/// Typography scale: Inter throughout. Fares/numbers use tabular figures.
abstract final class AppText {
  static const tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color primary, Color secondary) {
    return const TextTheme().copyWith(
      displayLarge: _inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineLarge: _inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      headlineMedium: _inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      headlineSmall: _inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      titleLarge: _inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleMedium: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleSmall: _inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      bodyLarge: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.4,
      ),
      bodyMedium: _inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.4,
      ),
      bodySmall: _inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      labelLarge: _inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.2,
      ),
      labelMedium: _inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.2,
      ),
      labelSmall: _inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.2,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Fare / numeric display style — Inter SemiBold with tabular figures.
  static TextStyle fare(
    BuildContext context, {
    double size = 32,
    FontWeight weight = FontWeight.w700,
  }) => _inter(
    fontSize: size,
    fontWeight: weight,
    color: context.textPrimary,
    fontFeatures: tabular,
    letterSpacing: -0.5,
    height: 1.1,
  );

  /// PIN / reference codes: bold, tabular, widely tracked.
  static TextStyle mono(BuildContext context, {double size = 28}) => _inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: context.isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
    letterSpacing: 4,
    fontFeatures: tabular,
  );
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const sheet = 24.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const screen = EdgeInsets.symmetric(horizontal: 16);
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.borderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.darkBorder : AppColors.primaryLight,
      onPrimaryContainer: isDark ? Colors.white : AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      tertiary: AppColors.accentGold,
      onTertiary: AppColors.primaryDark,
      error: AppColors.dangerRed,
      onError: Colors.white,
      errorContainer: AppColors.dangerTint,
      onErrorContainer: AppColors.dangerRed,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      surfaceContainerHighest: bg,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: kFontFamily,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: AppText.textTheme(textPrimary, textSecondary),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: _inter(color: textSecondary, fontSize: 15),
        labelStyle: _inter(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark ? AppColors.darkBorder : AppColors.primaryLight,
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: _inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? AppColors.successTeal : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: _inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.primaryBlue,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
        labelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primaryBlue,
        textColor: textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
      ),
    );
  }
}
