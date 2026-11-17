import 'package:flutter/material.dart';

class TezColors {
  static const yellow = Color(0xFFFFC107);
  static const yellowDeep = Color(0xFFF5A400);
  static const yellowSoft = Color(0xFFFFF3C9);
  static const pink = Color(0xFFFF4D6D);
  static const pinkDeep = Color(0xFFE43758);
  static const pinkSoft = Color(0xFFFFE4EA);
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFF6F0);
  static const ink = Color(0xFF2A2118);
  static const muted = Color(0xFF8C7368);
  static const line = Color(0xFFF0E1D6);
  static const green = Color(0xFF1E8A4C);
}

ThemeData buildTezTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TezColors.yellow,
    brightness: Brightness.light,
  ).copyWith(
    primary: TezColors.yellowDeep,
    onPrimary: TezColors.ink,
    secondary: TezColors.pink,
    onSecondary: TezColors.white,
    surface: TezColors.white,
    onSurface: TezColors.ink,
    error: const Color(0xFFC62828),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TezColors.cream,
    splashColor: TezColors.pink.withValues(alpha: 0.08),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: TezColors.ink, letterSpacing: -0.6),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: TezColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: TezColors.ink),
      bodyMedium: TextStyle(color: TezColors.ink, height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TezColors.cream,
      foregroundColor: TezColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: TezColors.ink),
    ),
    cardTheme: CardThemeData(
      color: TezColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: TezColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TezColors.yellow,
        foregroundColor: TezColors.ink,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TezColors.ink,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: TezColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TezColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: TezColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TezColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TezColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TezColors.pink, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TezColors.white,
      indicatorColor: TezColors.yellowSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
          color: TezColors.ink,
        );
      }),
    ),
    dividerColor: TezColors.line,
  );
}
