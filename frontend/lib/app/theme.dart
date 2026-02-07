import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red, // Pokémon Red
        brightness: Brightness.light,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        elevation: 1,
        labelType: NavigationRailLabelType.all,
      ),
    );
  }
}
