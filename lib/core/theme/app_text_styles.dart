import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application text styles
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'NotoSansLao';
  static const String fontFamilyRoboto = "roboto";
  static const String fontFamilyInter = "inter";
  static const String fontFamilyOCR_B = "OCR-B";

  // Headline Styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const TextStyle headline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.onBackground,
    height: 1.3,
  );

  // Subtitle Styles
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: AppColors.onBackground,
    height: 1.4,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.onBackground,
    height: 1.4,
  );

  // Body Styles
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onBackground,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.onBackground,
    height: 1.4,
  );

  // Button and Label Styles
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.gray600,
    height: 1.3,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: AppColors.gray600,
    height: 1.3,
  );

  // App Bar Title
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.onPrimary,
    height: 1.2,
  );

  // Form Field Styles
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gray700,
    height: 1.2,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
    height: 1.4,
  );

  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    height: 1.3,
  );

  // Dark Theme Variants
  static const TextStyle headline1Dark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    color: AppColors.darkOnBackground,
    height: 1.2,
  );

  static const TextStyle headline2Dark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    color: AppColors.darkOnBackground,
    height: 1.2,
  );

  static const TextStyle headline3Dark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.darkOnBackground,
    height: 1.3,
  );

  static const TextStyle headline4Dark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.darkOnBackground,
    height: 1.3,
  );

  static const TextStyle headline5Dark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.darkOnBackground,
    height: 1.3,
  );

  static const TextStyle headline6Dark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.darkOnBackground,
    height: 1.3,
  );

  static const TextStyle subtitle1Dark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: AppColors.darkOnBackground,
    height: 1.4,
  );

  static const TextStyle subtitle2Dark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.darkOnBackground,
    height: 1.4,
  );

  static const TextStyle body1Dark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.darkOnBackground,
    height: 1.5,
  );

  static const TextStyle body2Dark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.darkOnBackground,
    height: 1.4,
  );

  static const TextStyle captionDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.gray400,
    height: 1.3,
  );

  static const TextStyle overlineDark = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: AppColors.gray400,
    height: 1.3,
  );

  static const TextStyle appBarTitleDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.darkOnSurface,
    height: 1.2,
  );

  static const TextStyle labelDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gray300,
    height: 1.2,
  );

  static const TextStyle hintDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
    height: 1.4,
  );

  // Custom Utility Methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  static TextStyle hintStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    fontFamily: fontFamily,
  );
}