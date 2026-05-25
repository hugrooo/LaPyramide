import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PyraTheme {
  // === Couleurs principales ===
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color primaryYellow = Color(0xFFFBBF24);
  static const Color primaryGreen = Color(0xFF10B981);

  // === Fonds ===
  static const Color bgDark = Color(0xFF0D0D1A);
  static const Color bgCard = Color(0xFF1A1A2E);
  static const Color bgSurface = Color(0xFF16213E);

  // === Textes ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C1CC);
  static const Color textMuted = Color(0xFF6B7280);

  // === Couleurs des rangées de la pyramide (bas → haut) ===
  static const List<Color> pyramidRowColors = [
    Color(0xFF10B981), // Rangée 1 (1 gorgée) - vert
    Color(0xFF3B82F6), // Rangée 2 (2 gorgées) - bleu
    Color(0xFFF59E0B), // Rangée 3 (3 gorgées) - jaune
    Color(0xFFEF4444), // Rangée 4 (4 gorgées) - rouge
    Color(0xFF8B5CF6), // Rangée 5 (5 gorgées) - violet (sommet)
  ];

  // === Gradients ===
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
  );

  static const LinearGradient orangeYellowGradient = LinearGradient(
    colors: [primaryOrange, primaryYellow],
  );

  static const LinearGradient festiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPink, primaryOrange],
  );

  // === Ombres / Glow ===
  static List<BoxShadow> glowPurple = [
    BoxShadow(color: primaryPurple.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
  ];
  static List<BoxShadow> glowPink = [
    BoxShadow(color: primaryPink.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
  ];
  static List<BoxShadow> glowOrange = [
    BoxShadow(color: primaryOrange.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
  ];

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );

  // === ThemeData ===
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primaryPurple,
          secondary: primaryPink,
          tertiary: primaryOrange,
          surface: bgSurface,
          background: bgDark,
        ),
        textTheme: GoogleFonts.fredokaTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              color: textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            displayMedium: TextStyle(
              color: textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            headlineLarge: TextStyle(
              color: textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
            bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
            labelLarge: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: primaryPurple.withOpacity(0.5),
            textStyle: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.fredoka(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
      );
}
