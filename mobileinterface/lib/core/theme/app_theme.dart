import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  /// ThemeData para tema claro
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryLight,
      onSecondary: Colors.white,
      error: AppColors.errorLight,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      tertiary: AppColors.infoLight,
      onTertiary: Colors.white,
      primaryContainer: AppColors.primaryLight.withValues(alpha:0.15),
      onPrimaryContainer: AppColors.primaryLight,
      secondaryContainer: AppColors.secondaryLight.withValues(alpha:0.15),
      onSecondaryContainer: AppColors.secondaryLight,
      surfaceTint: AppColors.primaryLight,
      outline: const Color(0xFFBDBDBD),
      outlineVariant: const Color(0xFFE0E0E0),
      shadow: Colors.black.withValues(alpha:0.2),
      scrim: Colors.black.withValues(alpha:0.5),
      inversePrimary: AppColors.primaryDark,
      inverseSurface: const Color(0xFF121212),
      onInverseSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTextStyles.light,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: AppTextStyles.light.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          textStyle: AppTextStyles.light.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          textStyle: AppTextStyles.light.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: AppTextStyles.light.bodyMedium!.copyWith(color: AppColors.textSecondaryLight),
        labelStyle: AppTextStyles.light.bodyMedium,
        border: _inputBorder(const Color(0xFFBDBDBD)),
        enabledBorder: _inputBorder(const Color(0xFFBDBDBD)),
        focusedBorder: _inputBorder(AppColors.primaryLight, width: 2),
        errorBorder: _inputBorder(AppColors.errorLight),
        focusedErrorBorder: _inputBorder(AppColors.errorLight, width: 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerTheme: const DividerThemeData(thickness: 1, space: 24),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTextStyles.dark.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer,
        labelStyle: AppTextStyles.light.bodySmall!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// ThemeData para tema escuro
  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: Colors.black,
      secondary: AppColors.secondaryDark,
      onSecondary: Colors.black,
      error: AppColors.errorDark,
      onError: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      tertiary: AppColors.infoDark,
      onTertiary: Colors.black,
      primaryContainer: AppColors.primaryDark.withValues(alpha:0.18),
      onPrimaryContainer: AppColors.primaryDark,
      secondaryContainer: AppColors.secondaryDark.withValues(alpha:0.18),
      onSecondaryContainer: AppColors.secondaryDark,
      surfaceTint: AppColors.primaryDark,
      outline: const Color(0xFF424242),
      outlineVariant: const Color(0xFF2E2E2E),
      shadow: Colors.black.withValues(alpha:0.6),
      scrim: Colors.black.withValues(alpha:0.8),
      inversePrimary: AppColors.primaryLight,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: AppTextStyles.dark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: AppTextStyles.dark.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          textStyle: AppTextStyles.dark.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          textStyle: AppTextStyles.dark.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        hintStyle: AppTextStyles.dark.bodyMedium!.copyWith(color: AppColors.textSecondaryDark),
        labelStyle: AppTextStyles.dark.bodyMedium,
        border: _inputBorder(const Color(0xFF424242)),
        enabledBorder: _inputBorder(const Color(0xFF424242)),
        focusedBorder: _inputBorder(AppColors.primaryDark, width: 2),
        errorBorder: _inputBorder(AppColors.errorDark),
        focusedErrorBorder: _inputBorder(AppColors.errorDark, width: 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerTheme: const DividerThemeData(thickness: 1, space: 24, color: Color(0xFF2E2E2E)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: AppTextStyles.dark.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer,
        labelStyle: AppTextStyles.dark.bodySmall!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
