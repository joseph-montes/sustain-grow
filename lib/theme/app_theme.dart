import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ────────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color lightGreen = Color(0xFF52B788);
  static const Color mintGreen = Color(0xFFB7E4C7);
  static const Color darkGreen = Color(0xFF1B4332);
  static const Color accentAmber = Color(0xFFFFB703);
  static const Color accentOrange = Color(0xFFFB8500);
  static const Color backgroundLight = Color(0xFFF8FBF9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2D23);
  static const Color textSecondary = Color(0xFF4E6B5A);
  static const Color textMuted = Color(0xFF8FAF9A);
  static const Color dividerColor = Color(0xFFE4EDE8);
  static const Color errorRed = Color(0xFFE63946);
  static const Color warningOrange = Color(0xFFFF9F1C);
  static const Color infoBlue = Color(0xFF168AFF);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, lightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkGreen, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF52B788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Typography ───────────────────────────────────────────────────────────────
  static const TextStyle headingXL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: textMuted,
    height: 1.4,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  // ── Box Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primaryGreen.withOpacity(0.20),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Border Radius ────────────────────────────────────────────────────────────
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(20));

  // ── Theme Data ───────────────────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: lightGreen,
          surface: backgroundLight,
          background: backgroundLight,
          error: errorRed,
        ),
        scaffoldBackgroundColor: backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: mintGreen,
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              );
            }
            return const TextStyle(color: textMuted, fontSize: 11);
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: primaryGreen, size: 24);
            }
            return const IconThemeData(color: textMuted, size: 22);
          }),
          elevation: 8,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          color: cardBackground,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F5F2),
          border: OutlineInputBorder(
            borderRadius: buttonRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: buttonRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: buttonRadius,
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: buttonRadius,
            borderSide: const BorderSide(color: errorRed, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: textMuted),
        ),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          backgroundColor: mintGreen.withOpacity(0.3),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
