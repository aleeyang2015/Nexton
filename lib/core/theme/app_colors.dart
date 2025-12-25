import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF08123A);
  static const Color primaryVariant = Color(0xFF0E2067);
  static const Color secondary = Color(0xFF3386FF);
  static const Color secondaryVariant = Color(0xFF5C9DFF);

  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF737373);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color subTitle = Color(0xff8C8C8C);
  static const Color secondaryTxt = Color(0xff4B5563);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = Color(0xFFE00C16);

  // Gray Scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color danger = Color(0xFFF44336);

  // Semantic Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color away = Color(0xFFFF9800);
  static const Color busy = Color(0xFFF44336);

  // Social Media Colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color google = Color(0xFF4285F4);
  static const Color linkedin = Color(0xFF0077B5);
  static const Color instagram = Color(0xFFE4405F);

  // Brand Colors (customizable)
  static const Color brandPrimary = Color(0xFF6200EE);
  static const Color brandSecondary = Color(0xFF03DAC6);
  static const Color brandAccent = Color(0xFFFF5722);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFFBB86FC);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
}

/// Material color palette generator
class MaterialColorGenerator {
  static MaterialColor createMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }
}