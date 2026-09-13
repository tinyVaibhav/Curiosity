import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strict 4pt / 8pt grid spacing scale - Anti-Slop constraint
class GeistSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Standard border radiuses
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
}

/// Centralized Geist Design Tokens
class GeistColors {
  // Dark Palette
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkSurfaceElevated = Color(0xFF181818);
  static const Color darkBorder = Color(0x1AFFFFFF); // white/10
  static const Color darkBorderActive = Color(0x33FFFFFF); // white/20
  static const Color darkTextPrimary = Color(0xFFEDEDED);
  static const Color darkTextSecondary = Color(0xFF888888);
  static const Color darkTextTertiary = Color(0xFF8E8E8E); // WCAG AA 5.8:1 on dark surface

  // Light Palette
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F7F7);
  static const Color lightSurfaceElevated = Color(0xFFEFEFEF);
  static const Color lightBorder = Color(0x1A000000); // black/10
  static const Color lightBorderActive = Color(0x33000000); // black/20
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF595959); // WCAG AA 5.0:1 on light surface

  // Accent / Status
  static const Color success = Color(0xFF10B981);
  static const Color successTextLight = Color(0xFF047857); // 4.8:1 on light green tint
  static const Color errorTextLight = Color(0xFFB91C1C);   // 4.9:1 on light red tint
  static const Color accent = Color(0xFFFFFFFF);
}

class GeistTheme {
  /// Dark Theme (Pure Black Vercel/Geist Aesthetic)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GeistColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: GeistColors.darkSurface,
        primary: GeistColors.darkTextPrimary,
        secondary: GeistColors.darkTextSecondary,
        outline: GeistColors.darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GeistColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: GeistColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: GeistColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
          side: const BorderSide(color: GeistColors.darkBorder, width: 1),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: GeistColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: GeistColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: GeistColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: GeistColors.darkTextSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GeistColors.darkTextSecondary,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: GeistColors.darkTextTertiary,
        ),
      ),
    );
  }

  /// Light Theme (Pure White Vercel/Geist Aesthetic)
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GeistColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: GeistColors.lightSurface,
        primary: GeistColors.lightTextPrimary,
        secondary: GeistColors.lightTextSecondary,
        outline: GeistColors.lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GeistColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: GeistColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: GeistColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GeistSpacing.radiusLg),
          side: const BorderSide(color: GeistColors.lightBorder, width: 1),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: GeistColors.lightTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: GeistColors.lightTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: GeistColors.lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: GeistColors.lightTextSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GeistColors.lightTextSecondary,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: GeistColors.lightTextTertiary,
        ),
      ),
    );
  }
}
