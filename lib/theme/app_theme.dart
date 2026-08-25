import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryOrange = Color(0xFFF95716);
  static const Color primaryOrangeHover = Color(0xFFE0470A);
  static const Color primaryOrangeLight = Color(0xFFFFF0EB);
  static const Color primaryOrangeBorder = Color(0xFFFFD4C2);

  // Surface Colors - Light
  static const Color bgLight = Color(0xFFFAFAFC);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color inputBgLight = Color(0xFFF3F4F6);

  // Surface Colors - Dark
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color bgCardDark = Color(0xFF16181D);
  static const Color bgCardDarkBorder = Color(0xFF242834);
  static const Color inputBgDark = Color(0xFF1F222B);

  // Text Colors - Light
  static const Color textDark = Color(0xFF0F1012);
  static const Color textMuted = Color(0xFF5E626E);

  // Text Colors - Dark
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFF9AA0B4);

  // Standard Corner Radii Design Tokens
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusFull = 9999.0;

  // ThemeData Theme Definitions
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryOrange,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: borderLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryOrange,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: const BorderSide(color: bgCardDarkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper getters based on BuildContext theme mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBgColor(BuildContext context) {
    return isDarkMode(context) ? bgDark : bgLight;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? bgCardDark : bgCardLight;
  }

  static Color getCardBgColor(BuildContext context) {
    return getSurfaceColor(context);
  }

  static Color getHeaderBgColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF0F1117) : Colors.white;
  }

  static Color getBorderColor(BuildContext context) {
    return isDarkMode(context) ? bgCardDarkBorder : borderLight;
  }

  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? textLight : textDark;
  }

  static Color getMutedTextColor(BuildContext context) {
    return isDarkMode(context) ? textMutedDark : textMuted;
  }

  static Color getTextMutedColor(BuildContext context) {
    return getMutedTextColor(context);
  }

  static Color getInputBgColor(BuildContext context) {
    return isDarkMode(context) ? inputBgDark : inputBgLight;
  }

  static Color getInputFillColor(BuildContext context) {
    return getInputBgColor(context);
  }

  static Color getPrimaryLightColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF261814) : primaryOrangeLight;
  }

  static Color getPrimaryBorderColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF422119) : primaryOrangeBorder;
  }

  static Color getTrackColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF282B36) : const Color(0xFFEEECE6);
  }

  // Typography Styles
  static TextStyle getDisplayFont({
    double fontSize = 48,
    FontWeight fontWeight = FontWeight.bold,
    Color color = textDark,
    double height = 1.15,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: -0.8,
    );
  }

  static TextStyle getBodyFont({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textMuted,
    double height = 1.5,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
