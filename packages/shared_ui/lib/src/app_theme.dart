import 'package:flutter/material.dart';

ThemeData buildPdoTheme() {
  const seed = Color(0xFF0F766E);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: seed,
    secondary: const Color(0xFFF97316),
    surface: const Color(0xFFFFFBF5),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF4EFE6),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: const Color(0xFF1F2937),
      displayColor: const Color(0xFF0F172A),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}
