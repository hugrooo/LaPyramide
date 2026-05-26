import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PyraTheme {
  // === Couleurs principales (Deep Blue / Vibrant Accents) ===
  static const Color primaryCyan = Color(0xFF00D1FF);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFE81CFF);
  static const Color primaryBlue = Color(0xFF3B82F6);
  
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color primaryYellow = Color(0xFFFBBF24);
  static const Color primaryGreen = Color(0xFF10B981);
  
  // === Fonds (Dark Space / Glass) ===
  static const Color bgDark = Color(0xFF050814); // Ultra dark navy blue
  static const Color bgCard = Color(0xFF0F1530); // Dark tinted blue for cards
  static const Color bgSurface = Color(0xFF182042); // Elevated surface

  // === Textes ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF475569); // Slate 600

  // === Couleurs des rangées de la pyramide (bas → haut) ===
  static const List<Color> pyramidRowColors = [
    Color(0xFF10B981), // Rangée 1 (1 gorgée) - vert
    Color(0xFF3B82F6), // Rangée 2 (2 gorgées) - bleu
    Color(0xFFF59E0B), // Rangée 3 (3 gorgées) - jaune
    Color(0xFFEF4444), // Rangée 4 (4 gorgées) - rouge
    Color(0xFF00D1FF), // Rangée 5 (5 gorgées) - cyan (sommet)
  ];

  // === Gradients ===
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060B1C), Color(0xFF091228), Color(0xFF040610)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D1FF), Color(0xFF0066FF)],
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPink],
  );

  static const LinearGradient festiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE81CFF), Color(0xFF8B5CF6), Color(0xFF00D1FF)],
  );

  static const LinearGradient orangeYellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, primaryYellow],
  );

  // === Ombres / Glow ===
  static List<BoxShadow> glowCyan = [
    BoxShadow(color: primaryCyan.withOpacity(0.6), blurRadius: 24, spreadRadius: 2),
    BoxShadow(color: primaryCyan.withOpacity(0.2), blurRadius: 48, spreadRadius: 8),
  ];

  static List<BoxShadow> glowPurple = [
    BoxShadow(color: primaryPurple.withOpacity(0.6), blurRadius: 24, spreadRadius: 2),
  ];

  static List<BoxShadow> glowOrange = [
    BoxShadow(color: primaryOrange.withOpacity(0.6), blurRadius: 24, spreadRadius: 2),
  ];

  static List<BoxShadow> glowPink = [
    BoxShadow(color: primaryPink.withOpacity(0.6), blurRadius: 24, spreadRadius: 2),
  ];

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.6),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  // === ThemeData ===
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primaryCyan,
          secondary: primaryPurple,
          tertiary: primaryPink,
          surface: bgSurface,
          background: bgDark,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              color: textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w900, // Plus gras pour un effet pop
              letterSpacing: 1.2,
            ),
            displayMedium: TextStyle(
              color: textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
            headlineLarge: TextStyle(
              color: textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            bodyLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            bodyMedium: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            labelLarge: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 12,
            shadowColor: primaryCyan.withOpacity(0.6),
            textStyle: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 12,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgCard,
          elevation: 24,
          shadowColor: primaryPurple.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.nunito(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          iconTheme: const IconThemeData(color: textPrimary, size: 28),
        ),
      );
}
