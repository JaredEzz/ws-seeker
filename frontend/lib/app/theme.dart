import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // 1. Typography (Inter-like)
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: Tokens.textDisplay,
        displayColor: Tokens.textDisplay,
      ),

      // 2. Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Tokens.stone900,
        onPrimary: Tokens.white,
        secondary: Tokens.stone100,
        onSecondary: Tokens.stone900,
        error: Tokens.destructive,
        onError: Tokens.white,
        surface: Tokens.surfaceCard,
        onSurface: Tokens.textDisplay,
        outline: Tokens.borderDefault,
      ),

      scaffoldBackgroundColor: Tokens.surfaceBackground,
      dividerColor: Tokens.borderDefault,

      // 3. Components Styling

      // Cards: White, Bordered, Low Shadow
      cardTheme: CardTheme(
        color: Tokens.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.borderDefault, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons: Black background, sharp corners
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Tokens.stone900,
          foregroundColor: Tokens.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16, vertical: Tokens.space16),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Buttons: White background, border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Tokens.surfaceCard,
          foregroundColor: Tokens.stone900,
          side: const BorderSide(color: Tokens.borderDefault),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16, vertical: Tokens.space16),
        ),
      ),

      // Text Button: Ghost style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Tokens.stone900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),

      // Inputs: Warm fill, clean borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.surfaceInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: Tokens.space12, vertical: Tokens.space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: const BorderSide(color: Tokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: const BorderSide(color: Tokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          borderSide: const BorderSide(color: Tokens.borderFocus, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Tokens.textSecondary),
        hintStyle: const TextStyle(color: Tokens.textPlaceholder),
      ),

      // Navigation: Clean sidebar
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Tokens.surfaceCard,
        indicatorColor: Tokens.stone100,
        selectedIconTheme: const IconThemeData(color: Tokens.stone900),
        unselectedIconTheme: const IconThemeData(color: Tokens.textSecondary),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(
          color: Tokens.stone900,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Tokens.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        groupAlignment: -1.0,
      ),

      // AppBar: Border bottom, no shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.surfaceCard,
        foregroundColor: Tokens.textDisplay,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Tokens.borderDefault)),
        titleTextStyle: TextStyle(
          color: Tokens.textDisplay,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Tokens.stone900,
        foregroundColor: Tokens.textOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
