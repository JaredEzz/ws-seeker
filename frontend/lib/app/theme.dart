import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Shadcn/Zinc Color Palette
  static const _zinc950 = Color(0xFF09090b);
  static const _zinc900 = Color(0xFF18181b);
  static const _zinc500 = Color(0xFF71717a);
  static const _zinc200 = Color(0xFFe4e4e7);
  static const _zinc100 = Color(0xFFf4f4f5);
  static const _white = Color(0xFFFFFFFF);
  static const _destructive = Color(0xFFef4444);

  static const double _radius = 6.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // 1. Typography (Inter-like)
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: _zinc950,
        displayColor: _zinc950,
      ),

      // 2. Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _zinc900,
        onPrimary: _white,
        secondary: _zinc100,
        onSecondary: _zinc900,
        error: _destructive,
        onError: _white,
        surface: _white,
        onSurface: _zinc950,
        outline: _zinc200, // Border color
      ),

      scaffoldBackgroundColor: _white,
      dividerColor: _zinc200,

      // 3. Components Styling

      // Cards: White, Bordered, Low Shadow
      cardTheme: CardTheme(
        color: _white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: _zinc200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons: Black background, sharp corners
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _zinc900,
          foregroundColor: _white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Buttons: White background, border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: _zinc900,
          side: const BorderSide(color: _zinc200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),

      // Text Button: Ghost style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _zinc900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),

      // Inputs: Clean borders, no fill
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _zinc200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _zinc200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _zinc900, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _zinc500),
        hintStyle: const TextStyle(color: _zinc200),
      ),

      // Navigation: Clean sidebar
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _white,
        indicatorColor: _zinc100, // Subtle background for selected
        selectedIconTheme: const IconThemeData(color: _zinc900),
        unselectedIconTheme: const IconThemeData(color: _zinc500),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(
          color: _zinc900,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: _zinc500,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        groupAlignment: -1.0, // Top align
      ),

      // AppBar: Border bottom, no shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: _white,
        foregroundColor: _zinc950,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: _zinc200)),
        titleTextStyle: TextStyle(
          color: _zinc950,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _zinc900,
        foregroundColor: _white,
        elevation: 2,
        shape: CircleBorder(), // Keep generic or change to rounded rect
      ),
    );
  }
}
