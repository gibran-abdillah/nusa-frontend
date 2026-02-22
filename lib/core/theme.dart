import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1C1C1E);
  static const Color backgroundColor = Color(0xFFF7F7F9);
  static const Color cardColor = Colors.white;
  static const Color redAccent = Color(0xFFFF4D4D);
  static const Color greenAccent = Color(0xFF2ECC71);
  static const Color blueAccent = Color(0xFF3498DB);
  static const Color textBlack = Color(0xFF1C1C1E);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color textLightGrey = Color(0xFFC7C7CC);
  static const Color dividerColor = Color(0xFFE5E5EA);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: redAccent,
        surface: cardColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLightGrey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
