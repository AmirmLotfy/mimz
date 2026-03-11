import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mimz Design Tokens — extracted from screen designs
class MimzColors {
  MimzColors._();

  // Core palette
  static const Color cloudBase = Color(0xFFF7F4ED);
  static const Color deepInk = Color(0xFF151417);
  static const Color mossCore = Color(0xFF5E7442);
  static const Color acidLime = Color(0xFFC8F169);
  static const Color persimmonHit = Color(0xFFF26A3D);
  static const Color dustyGold = Color(0xFFD5A13B);
  static const Color mistBlue = Color(0xFF7DB9D8);

  // Dark live surfaces
  static const Color nightSurface = Color(0xFF1C1D21);
  static const Color mapShadow = Color(0xFF23262B);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAF8F3);
  static const Color borderLight = Color(0xFFE8E4DC);
  static const Color textSecondary = Color(0xFF8A8680);
  static const Color textTertiary = Color(0xFFB5B0A8);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
}

class MimzSpacing {
  MimzSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;
}

class MimzRadius {
  MimzRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

class MimzTypography {
  MimzTypography._();

  /// Editorial serif — Playfair Display for hero headlines
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: MimzColors.deepInk,
    height: 1.15,
  );

  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: MimzColors.deepInk,
    height: 1.2,
  );

  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: MimzColors.deepInk,
    height: 1.25,
  );

  /// Clean sans — Inter for body and UI
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MimzColors.deepInk,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MimzColors.deepInk,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MimzColors.deepInk,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MimzColors.deepInk,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MimzColors.deepInk,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MimzColors.textSecondary,
    height: 1.5,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: MimzColors.deepInk,
    letterSpacing: 0.8,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: MimzColors.textSecondary,
    letterSpacing: 1.2,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: MimzColors.textTertiary,
    letterSpacing: 1.5,
  );
}

class MimzTheme {
  MimzTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: MimzColors.cloudBase,
        colorScheme: const ColorScheme.light(
          primary: MimzColors.mossCore,
          secondary: MimzColors.persimmonHit,
          tertiary: MimzColors.acidLime,
          surface: MimzColors.cloudBase,
          onPrimary: MimzColors.white,
          onSecondary: MimzColors.white,
          onSurface: MimzColors.deepInk,
          outline: MimzColors.borderLight,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MimzColors.cloudBase,
          foregroundColor: MimzColors.deepInk,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: MimzTypography.headlineSmall,
        ),
        cardTheme: CardThemeData(
          color: MimzColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MimzRadius.lg),
            side: const BorderSide(color: MimzColors.borderLight),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: MimzColors.white,
          selectedItemColor: MimzColors.mossCore,
          unselectedItemColor: MimzColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MimzColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.mossCore, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MimzSpacing.base,
            vertical: MimzSpacing.lg,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MimzColors.nightSurface,
        colorScheme: const ColorScheme.dark(
          primary: MimzColors.persimmonHit,
          secondary: MimzColors.acidLime,
          surface: MimzColors.nightSurface,
          onPrimary: MimzColors.white,
          onSecondary: MimzColors.deepInk,
          onSurface: MimzColors.white,
        ),
      );
}
