import 'package:flutter/material.dart';

class InterbankTheme {
  static const blue = Color(0xFF003A70);
  static const green = Color(0xFF00A94F);
  static const sky = Color(0xFFE7F4FF);
  static const ink = Color(0xFF1B2733);
  static const lime = Color(0xFFD7F36B);
  static const sand = Color(0xFFFFF4D8);
  static const field = Color(0xFF153D35);
  static const copper = Color(0xFFE6A23C);
  static const cloud = Color(0xFFF6F8FB);

  static ThemeData customer() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: green,
      tertiary: const Color(0xFF24B5FF),
      surface: Colors.white,
    );

    return _base(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF3F8FC),
      appBarBackground: Colors.white,
      navigationIndicator: sky,
      primaryButtonColor: green,
    );
  }

  static ThemeData sales() {
    final scheme = ColorScheme.fromSeed(
      seedColor: field,
      primary: field,
      secondary: copper,
      tertiary: lime,
      surface: Colors.white,
    );

    return _base(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF6F5EF),
      appBarBackground: const Color(0xFF102A26),
      appBarForeground: Colors.white,
      navigationIndicator: const Color(0xFFEAF3DF),
      primaryButtonColor: field,
    );
  }

  static ThemeData light() => customer();

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color navigationIndicator,
    required Color primaryButtonColor,
    Color appBarForeground = ink,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryButtonColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: navigationIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? scheme.primary : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : const Color(0xFF64748B),
            size: selected ? 25 : 23,
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
        bodyMedium: TextStyle(color: ink),
      ),
    );
  }
}
