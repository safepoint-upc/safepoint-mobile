import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3b82f6);
  static const Color background = Color(0xFF0a0f1e);
  static const Color surface = Color(0xFF1e293b);
  static const Color surfaceVariant = Color(0xFF0f172a);
  static const Color border = Color(0xFF334155);
  static const Color textSecondary = Color(0xFF94a3b8);
  static const Color textMuted = Color(0xFF64748b);
  static const Color riskHigh = Color(0xFFef4444);
  static const Color riskMed = Color(0xFFf97316);
  static const Color riskLow = Color(0xFF22c55e);
  static const Color cardColor = Color(0xFF1e293b);

  static Color riskColor(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'ALTO': return riskHigh;
      case 'MEDIO': return riskMed;
      case 'BAJO': return riskLow;
      default: return textMuted;
    }
  }

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
    ),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0d1424),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0d1424),
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF475569),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1e293b), width: 1),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
  );
}
