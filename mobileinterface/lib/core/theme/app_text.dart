import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final TextTheme light = TextTheme(
    displayLarge: _h(32, FontWeight.bold, AppColors.textPrimaryLight),
    displayMedium: _h(28, FontWeight.bold, AppColors.textPrimaryLight),
    displaySmall: _h(24, FontWeight.w600, AppColors.textPrimaryLight),

    headlineMedium: _h(20, FontWeight.w600, AppColors.textPrimaryLight),
    headlineSmall: _h(18, FontWeight.w600, AppColors.textPrimaryLight),

    titleLarge: _h(18, FontWeight.w600, AppColors.textPrimaryLight),
    titleMedium: _h(16, FontWeight.w600, AppColors.textPrimaryLight),
    titleSmall: _h(14, FontWeight.w600, AppColors.textSecondaryLight),

    bodyLarge: _h(16, FontWeight.w400, AppColors.textPrimaryLight),
    bodyMedium: _h(14, FontWeight.w400, AppColors.textPrimaryLight),
    bodySmall: _h(12, FontWeight.w400, AppColors.textSecondaryLight),

    labelLarge: _h(14, FontWeight.w600, Colors.white),
    labelMedium: _h(12, FontWeight.w600, AppColors.textSecondaryLight),
    labelSmall: _h(11, FontWeight.w500, AppColors.textSecondaryLight),
  );

  static final TextTheme dark = TextTheme(
    displayLarge: _h(32, FontWeight.bold, AppColors.textPrimaryDark),
    displayMedium: _h(28, FontWeight.bold, AppColors.textPrimaryDark),
    displaySmall: _h(24, FontWeight.w600, AppColors.textPrimaryDark),

    headlineMedium: _h(20, FontWeight.w600, AppColors.textPrimaryDark),
    headlineSmall: _h(18, FontWeight.w600, AppColors.textPrimaryDark),

    titleLarge: _h(18, FontWeight.w600, AppColors.textPrimaryDark),
    titleMedium: _h(16, FontWeight.w600, AppColors.textPrimaryDark),
    titleSmall: _h(14, FontWeight.w600, AppColors.textSecondaryDark),

    bodyLarge: _h(16, FontWeight.w400, AppColors.textPrimaryDark),
    bodyMedium: _h(14, FontWeight.w400, AppColors.textPrimaryDark),
    bodySmall: _h(12, FontWeight.w400, AppColors.textSecondaryDark),

    labelLarge: _h(14, FontWeight.w600, Colors.black),
    labelMedium: _h(12, FontWeight.w600, AppColors.textSecondaryDark),
    labelSmall: _h(11, FontWeight.w500, AppColors.textSecondaryDark),
  );

  static TextStyle _h(double size, FontWeight weight, Color color) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.2);
}
