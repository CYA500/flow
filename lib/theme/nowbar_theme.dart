import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../capsule/capsule_manager.dart';

/// Now Bar Theme - Samsung One UI 8.5 inspired design system
class NowBarTheme {
  NowBarTheme._();

  // Samsung-inspired color palette
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color primaryGreen = Color(0xFF30D158);
  static const Color primaryOrange = Color(0xFFFF9F0A);
  static const Color primaryPink = Color(0xFFFF375F);
  static const Color primaryPurple = Color(0xFFBF5AF2);
  static const Color primaryCyan = Color(0xFF64D2FF);
  static const Color primaryYellow = Color(0xFFFFD60A);

  // Semantic colors
  static const Color successColor = Color(0xFF30D158);
  static const Color warningColor = Color(0xFFFF9F0A);
  static const Color errorColor = Color(0xFFFF375F);
  static const Color infoColor = Color(0xFF0A84FF);

  // Background colors
  static const Color backgroundColor = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF1C1C1E);
  static const Color cardColor = Color(0xFF2C2C2E);
  static const Color elevatedColor = Color(0xFF3A3A3C);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  static const Color textQuaternary = Color(0xFF48484A);

  // Glass morphism
  static const Color glassBackground = Color(0x1FFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // Gradients
  static const Gradient cardGradient = LinearGradient(
    colors: [
      Color(0x2E1C1C1E),
      Color(0x1E2C2C2E),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient blueGradient = LinearGradient(
    colors: [
      Color(0xE60A84FF),
      Color(0xB30066CC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient greenGradient = LinearGradient(
    colors: [
      Color(0xE630D158),
      Color(0xB324A040),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient orangeGradient = LinearGradient(
    colors: [
      Color(0xE6FF9F0A),
      Color(0xB3CC7F08),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient pinkGradient = LinearGradient(
    colors: [
      Color(0xE6FF375F),
      Color(0xB3CC2D4C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient rainbowGradient = LinearGradient(
    colors: [
      primaryBlue,
      primaryGreen,
      primaryOrange,
      primaryPink,
      primaryPurple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text styles
  static TextStyle get headlineStyle => const TextStyle(
    color: textPrimary,
    fontFamily: 'SamsungOne',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get titleStyle => const TextStyle(
    color: textPrimary,
    fontFamily: 'SamsungOne',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get subtitleStyle => const TextStyle(
    color: textSecondary,
    fontFamily: 'SamsungOne',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get bodyStyle => const TextStyle(
    color: textPrimary,
    fontFamily: 'SamsungOne',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get captionStyle => const TextStyle(
    color: textSecondary,
    fontFamily: 'SamsungOne',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get buttonStyle => const TextStyle(
    color: textPrimary,
    fontFamily: 'SamsungOne',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Dark theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryGreen,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: textSecondary,
        fontFamily: 'SamsungOne',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: textPrimary,
        fontFamily: 'SamsungOne',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: textSecondary,
        fontFamily: 'SamsungOne',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: textTertiary,
        fontFamily: 'SamsungOne',
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardTheme(
      color: cardColor.withOpacity(0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: glassBorder,
          width: 1,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryGreen;
        }
        return textTertiary;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryGreen.withOpacity(0.3);
        }
        return textQuaternary;
      }),
    ),
    dividerTheme: DividerThemeData(
      color: textQuaternary.withOpacity(0.5),
      thickness: 0.5,
    ),
  );

  // Glass morphism decoration
  static BoxDecoration glassDecoration({Color? tintColor}) => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        (tintColor ?? Colors.white).withOpacity(0.15),
        (tintColor ?? Colors.white).withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: glassBorder,
      width: 1,
    ),
  );

  // Glow effect for active elements
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withOpacity(intensity * 0.6),
      blurRadius: 20,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.3),
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];

  // Capsule color mapping
  static Color getCapsuleColor(CapsuleType type) {
    switch (type) {
      case CapsuleType.battery:
        return primaryBlue;
      case CapsuleType.weather:
        return primaryGreen;
      case CapsuleType.music:
        return primaryOrange;
      case CapsuleType.match:
        return primaryPink;
    }
  }

  static Gradient getCapsuleGradient(CapsuleType type) {
    switch (type) {
      case CapsuleType.battery:
        return blueGradient;
      case CapsuleType.weather:
        return greenGradient;
      case CapsuleType.music:
        return orangeGradient;
      case CapsuleType.match:
        return pinkGradient;
    }
  }
}
