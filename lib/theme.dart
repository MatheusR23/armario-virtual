import 'package:flutter/material.dart';

class C {
  static const primary = Color(0xFF516B7A);
  static const primaryDark = Color(0xFF344955);
  static const primaryLight = Color(0xFFDCE7ED);
  static const navActive = Color(0xFF4E6674);
  static const navIcon = Color(0xFFC5D2D9);
  static const bg = Color(0xFFF7F9FA);
  static const text = Color(0xFF1D2930);
  static const text2 = Color(0xFF5F6B72);
  static const success = Color(0xFF2E7D5B);
  static const warning = Color(0xFFC78724);
  static const warningBg = Color(0xFFF7E9D2);
  static const warningFg = Color(0xFF5E3C08);
  static const error = Color(0xFFB94A48);
  static const info = Color(0xFF3D6D8A);
  static const tile = Color(0xFFEAF0F3);
  static const seg = Color(0xFFE6ECEF);
  static const line = Color(0xFFE3E9EC);
  static const border = Color(0xFFC9D4DA);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.primary,
    primary: C.primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    error: C.error,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    textTheme: Typography.blackMountainView.apply(bodyColor: C.text, displayColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.primaryDark,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: C.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.primaryDark,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: C.primaryDark,
      side: const BorderSide(color: C.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.primaryDark),
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
