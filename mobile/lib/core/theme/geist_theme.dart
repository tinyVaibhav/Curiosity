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

  // Soft pillowy Scandinavian border radiuses
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
}

/// Centralized Nordic Clay & Sage Design Tokens
class GeistColors {
  // Dark Palette (Nordic Slate & Sage)
  static const Color darkBackground = Color(0xFF1A1D20); // Soothing dark graphite slate
  static const Color darkSurface = Color(0xFF24282C);    // Elevated mineral clay
  static const Color darkSurfaceElevated = Color(0xFF2C3136); // Modals, sheets, popovers
  static const Color darkBorder = Color(0x1FFFFFFF);     // Soft mineral border (12% white)
  static const Color darkBorderActive = Color(0x33FFFFFF); // 20% white
  static const Color darkTextPrimary = Color(0xFFEDE8E1); // Warm oat milk cream (>12:1)
  static const Color darkTextSecondary = Color(0xFF9BA3AB); // Muted slate (>5.0:1 on #24282C)
  static const Color darkTextTertiary = Color(0xFF949DA7);  // Compliant: >5.4:1 on #24282C

  // Light Palette (Warm Linen & Sage)
  static const Color lightBackground = Color(0xFFFAF8F5); // Warm unbleached linen paper
  static const Color lightSurface = Color(0xFFFFFFFF);    // Soft porcelain white
  static const Color lightSurfaceElevated = Color(0xFFF2EFE9); // Elevated linen
  static const Color lightBorder = Color(0x14000000);     // Subtle 8% black
  static const Color lightBorderActive = Color(0x28000000);
  static const Color lightTextPrimary = Color(0xFF1C1E21); // Deep warm charcoal (>13:1)
  static const Color lightTextSecondary = Color(0xFF5F6872); // Soft mineral slate (5.2:1)
  static const Color lightTextTertiary = Color(0xFF555E69);  // Compliant: >5.9:1 on #FFFFFF

  // Accent / Status (Organic Sage & Terracotta)
  static const Color accent = Color(0xFF5B8A72);           // Organic Sage Green (Graphical / fills)
  static const Color accentTextDark = Color(0xFF7CB698);   // Compliant: >6.8:1 text on dark surfaces
  static const Color accentLight = Color(0xFF3E6552);      // Deep Pine Sage (4.8:1 on light)
  static const Color streak = Color(0xFFD97757);           // Warm Terracotta flame
  static const Color streakLight = Color(0xFFB34924);      // Compliant: >5.0:1 on warm linen
  static const Color success = Color(0xFF4E876A);          // Forest Sage
  static const Color successTextLight = Color(0xFF2F664B); // 4.8:1 on light green tint
  static const Color error = Color(0xFFC85A54);            // Brick Red
  static const Color errorTextLight = Color(0xFFA83832);   // 4.9:1 on light red tint

  // Component Semantic Tokens
  static const Color quizCorrectBgDark = Color(0xFF1A3326);
  static const Color quizCorrectBgLight = Color(0xFFEAF5EE);
  static const Color quizIncorrectBgDark = Color(0xFF381F1E);
  static const Color quizIncorrectBgLight = Color(0xFFFBEBEA);
  static const Color bookmarkActiveBgDark = Color(0x33D97757);
  static const Color bookmarkActiveBgLight = Color(0x22B34924);
  static const Color dragHandleDark = Color(0xFF3A4046);
  static const Color dragHandleLight = Color(0xFFD6D0C7);

  // Modal / Surface & Streak Aliases
  static const Color darkModalBackground = darkSurfaceElevated;
  static const Color lightModalBackground = lightSurface;
  static const Color darkStreak = streak;
  static const Color lightStreak = streakLight;

  // Dynamic Theme Resolution Helpers
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color cardSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color modalBackground(bool isDark) => isDark ? darkModalBackground : lightModalBackground;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color borderActive(bool isDark) => isDark ? darkBorderActive : lightBorderActive;
  static Color primaryText(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color secondaryText(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color tertiaryText(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color sage(bool isDark) => isDark ? accent : accentLight;
  static Color sageText(bool isDark) => isDark ? accentTextDark : accentLight;
  static Color streakColor(bool isDark) => isDark ? streak : streakLight;
  static Color quizCorrectBg(bool isDark) => isDark ? quizCorrectBgDark : quizCorrectBgLight;
  static Color quizIncorrectBg(bool isDark) => isDark ? quizIncorrectBgDark : quizIncorrectBgLight;
  static Color bookmarkActiveBg(bool isDark) => isDark ? bookmarkActiveBgDark : bookmarkActiveBgLight;
  static Color dragHandle(bool isDark) => isDark ? dragHandleDark : dragHandleLight;
}

class GeistTheme {
  /// Dark Theme (Nordic Slate & Sage Aesthetic) - Cached instance
  static final ThemeData darkTheme = _buildDarkTheme();

  /// Light Theme (Warm Linen & Sage Aesthetic) - Cached instance
  static final ThemeData lightTheme = _buildLightTheme();

  static ThemeData _buildDarkTheme() {
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
        displayLarge: GoogleFonts.lora(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          color: GeistColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: GeistColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
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

  static ThemeData _buildLightTheme() {
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
        displayLarge: GoogleFonts.lora(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          color: GeistColors.lightTextPrimary,
        ),
        titleLarge: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: GeistColors.lightTextPrimary,
        ),
        titleMedium: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
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
