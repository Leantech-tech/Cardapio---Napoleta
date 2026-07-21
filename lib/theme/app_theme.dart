import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Napoleta palette
  static const Color brandPurple = Color(0xFF7B1FA2);
  static const Color brandPurpleDark = Color(0xFF4A148C);
  static const Color brandGreen = Color(0xFF00A650);
  static const Color brandYellow = Color(0xFFFFD600);
  static const Color honeyGold = Color(0xFFFFD600);

  // Typography scale
  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 13.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSize2Xl = 20.0;
  static const double fontSize3Xl = 22.0;
  static const double fontSize4Xl = 28.0;

  // Light theme specific
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color softBackground = Color(0xFFF8F9FA);

  // Dark theme specific
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkInputBg = Color(0xFF2A2A2A);

  // Adaptive helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : softBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : darkText;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : greyText;

  static Color divider(BuildContext context) =>
      isDark(context) ? darkBorder : borderGrey;

  static Color inputBg(BuildContext context) =>
      isDark(context) ? darkInputBg : lightGrey;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : borderGrey;

  static Color shadow(BuildContext context) =>
      isDark(context) ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static ThemeData get _baseTheme => ThemeData(
        useMaterial3: true,
        primaryColor: brandPurple,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  static ThemeData get lightTheme => _baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: softBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          primary: brandPurple,
          secondary: honeyGold,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: softBackground,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: fontSize4Xl,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: fontSize3Xl,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: fontSizeXl,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: fontSizeLg,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: fontSizeLg,
            fontWeight: FontWeight.w400,
            color: darkText,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: fontSizeMd,
            fontWeight: FontWeight.w400,
            color: greyText,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w400,
            color: greyText,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: lightGrey,
          selectedColor: brandPurple,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      );

  static ThemeData get darkTheme => _baseTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          primary: brandPurple,
          secondary: honeyGold,
          surface: darkSurface,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: darkBackground,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: fontSize4Xl,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: fontSize3Xl,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: fontSizeXl,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: fontSizeLg,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: fontSizeLg,
            fontWeight: FontWeight.w400,
            color: darkTextPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: fontSizeMd,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: fontSizeSm,
            fontWeight: FontWeight.w400,
            color: darkTextSecondary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkInputBg,
          selectedColor: brandPurple,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: darkTextPrimary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none,
          ),
        ),
      );
}
