import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: Tokens.textDisplay,
      displayColor: Tokens.textDisplay,
    );
    return _buildTheme(
      brightness: Brightness.light,
      textTheme: textTheme,
      primary: Tokens.stone900,
      onPrimary: Tokens.white,
      secondary: Tokens.stone100,
      onSecondary: Tokens.stone900,
      surface: Tokens.surfaceCard,
      onSurface: Tokens.textDisplay,
      outline: Tokens.borderDefault,
      scaffoldBg: Tokens.surfaceBackground,
      cardColor: Tokens.surfaceCard,
      cardBorder: Tokens.borderDefault,
      inputFill: Tokens.surfaceInputFill,
      borderDefault: Tokens.borderDefault,
      borderFocus: Tokens.borderFocus,
      textSecondary: Tokens.textSecondary,
      textPlaceholder: Tokens.textPlaceholder,
      navIndicator: Tokens.stone100,
      navSelectedIcon: Tokens.stone900,
      fabBg: Tokens.stone900,
      fabFg: Tokens.white,
      outlinedBtnBg: Tokens.surfaceCard,
      outlinedBtnFg: Tokens.stone900,
      textBtnFg: Tokens.stone900,
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: Tokens.stone100,
      displayColor: Tokens.stone100,
    );
    return _buildTheme(
      brightness: Brightness.dark,
      textTheme: textTheme,
      primary: Tokens.stone100,
      onPrimary: Tokens.stone900,
      secondary: Tokens.stone800,
      onSecondary: Tokens.stone100,
      surface: Tokens.stone900,
      onSurface: Tokens.stone100,
      outline: Tokens.stone700,
      scaffoldBg: Tokens.stone950,
      cardColor: Tokens.stone900,
      cardBorder: Tokens.stone700,
      inputFill: Tokens.stone800,
      borderDefault: Tokens.stone700,
      borderFocus: Tokens.stone300,
      textSecondary: Tokens.stone400,
      textPlaceholder: Tokens.stone500,
      navIndicator: Tokens.stone800,
      navSelectedIcon: Tokens.stone100,
      fabBg: Tokens.stone100,
      fabFg: Tokens.stone900,
      outlinedBtnBg: Tokens.stone900,
      outlinedBtnFg: Tokens.stone100,
      textBtnFg: Tokens.stone100,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required TextTheme textTheme,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color onSecondary,
    required Color surface,
    required Color onSurface,
    required Color outline,
    required Color scaffoldBg,
    required Color cardColor,
    required Color cardBorder,
    required Color inputFill,
    required Color borderDefault,
    required Color borderFocus,
    required Color textSecondary,
    required Color textPlaceholder,
    required Color navIndicator,
    required Color navSelectedIcon,
    required Color fabBg,
    required Color fabFg,
    required Color outlinedBtnBg,
    required Color outlinedBtnFg,
    required Color textBtnFg,
  }) {
    final semanticColors = brightness == Brightness.light
        ? SemanticColors.light
        : SemanticColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [semanticColors],

      // 1. Typography (Inter)
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,

      // 2. Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        error: Tokens.destructive,
        onError: Tokens.white,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),

      scaffoldBackgroundColor: scaffoldBg,
      dividerColor: borderDefault,

      // 3. Components Styling

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons: Primary fill
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16, vertical: Tokens.space16),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: outlinedBtnBg,
          foregroundColor: outlinedBtnFg,
          side: BorderSide(color: borderDefault),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16, vertical: Tokens.space16),
        ),
      ),

      // Text Button: Ghost style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textBtnFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: Tokens.space12, vertical: Tokens.space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: BorderSide(color: borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: BorderSide(color: borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: BorderSide(color: borderFocus, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textPlaceholder),
      ),

      // Navigation: Clean sidebar
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: navIndicator,
        selectedIconTheme: IconThemeData(color: navSelectedIcon),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: TextStyle(
          color: navSelectedIcon,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        groupAlignment: -1.0,
      ),

      // AppBar: Border bottom, no shadow
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: borderDefault)),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBg,
        foregroundColor: fabFg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}
