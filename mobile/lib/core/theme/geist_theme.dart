import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GeistSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
}

class GeistColors {
  static const Color darkBackground = Color(0xFF1A1D20);
  static const Color darkSurface = Color(0xFF24282C);
  static const Color darkSurfaceElevated = Color(0xFF2C3136);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkBorderActive = Color(0x33FFFFFF);
  static const Color darkTextPrimary = Color(0xFFEDE8E1);
  static const Color darkTextSecondary = Color(0xFF9BA3AB);
  static const Color darkTextTertiary = Color(0xFF949DA7);
  static const Color lightBackground = Color(0xFFFAF8F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF2EFE9);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightBorderActive = Color(0x28000000);
  static const Color lightTextPrimary = Color(0xFF1C1E21);
  static const Color lightTextSecondary = Color(0xFF5F6872);
  static const Color lightTextTertiary = Color(0xFF555E69);
  static const Color accent = Color(0xFF5B8A72);
  static const Color accentTextDark = Color(0xFF7CB698);
  static const Color accentLight = Color(0xFF3E6552);
  static const Color streak = Color(0xFFD97757);
  static const Color streakLight = Color(0xFFB34924);
  static const Color success = Color(0xFF4E876A);
  static const Color successTextLight = Color(0xFF2F664B);
  static const Color error = Color(0xFFC85A54);
  static const Color errorTextLight = Color(0xFFA83832);

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

  // Bottom Navigation Contrast Tokens
  static const Color lightNavActiveBackground = Color(0xFFE5EDE8);
  static const Color lightNavActiveBorder = Color(0xFFC6D8CD);
  static const Color lightNavActiveIcon = Color(0xFF2C4E3D);
  static const Color lightNavActiveText = Color(0xFF1C1E21);
  static const Color lightNavInactive = Color(0xFF7D8794);

  static const Color darkNavActiveBackground = Color(0xFF1C2A22);
  static const Color darkNavActiveBorder = Color(0xFF2B4536);
  static const Color darkNavActiveIcon = Color(0xFF8ECBB0);
  static const Color darkNavActiveText = Color(0xFFEDE8E1);
  static const Color darkNavInactive = Color(0xFF6F7782);

  static Color navActiveBackground(bool isDark) => isDark ? darkNavActiveBackground : lightNavActiveBackground;
  static Color navActiveBorder(bool isDark) => isDark ? darkNavActiveBorder : lightNavActiveBorder;
  static Color navActiveIcon(bool isDark) => isDark ? darkNavActiveIcon : lightNavActiveIcon;
  static Color navActiveText(bool isDark) => isDark ? darkNavActiveText : lightNavActiveText;
  static Color navInactive(bool isDark) => isDark ? darkNavInactive : lightNavInactive;

  // Functional Semantic Tokens
  static Color surfaceCanvas(bool isDark) => background(isDark);
  static Color surfaceCard(bool isDark) => cardSurface(isDark);
  static Color surfaceElevated(bool isDark) => isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color borderHairline(bool isDark) => border(isDark);
  static Color textPrimary(bool isDark) => primaryText(isDark);
  static Color textSecondary(bool isDark) => secondaryText(isDark);
  static Color textMuted(bool isDark) => tertiaryText(isDark);
  static Color accentBrand(bool isDark) => sage(isDark);
  static Color accentStreak(bool isDark) => streakColor(isDark);
}

class GeistTheme {
  /// Dark Theme - Cached instance
  static final ThemeData darkTheme = _buildDarkTheme();

  /// Light Theme - Cached instance
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

class GeistMotion {
  static const durationFast = Duration(milliseconds: 200);
  static const durationStandard = Duration(milliseconds: 320);
  static const springCurve = Curves.fastLinearToSlowEaseIn;
}
