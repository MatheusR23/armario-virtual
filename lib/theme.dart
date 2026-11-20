import 'dart:ui' show ColorSpace;

import 'package:flutter/material.dart';

/// `true` quando o tema escuro está ativo. Definido em `main.dart` antes de
/// montar o app; trocar o tema remonta a árvore inteira.
bool appDark = false;

/// Cor que muda com o tema, mas pode ser usada em `const` (como as do
/// Cupertino): todas as leituras passam pela cor do tema ativo.
class AppColor implements Color {
  final int light;
  final int dark;
  const AppColor(this.light, this.dark);

  Color get _c => Color(appDark ? dark : light);

  @override
  double get a => _c.a;
  @override
  double get r => _c.r;
  @override
  double get g => _c.g;
  @override
  double get b => _c.b;
  @override
  ColorSpace get colorSpace => _c.colorSpace;
  // ignore: deprecated_member_use
  @override
  int get value => _c.toARGB32();
  @override
  int toARGB32() => _c.toARGB32();
  // ignore: deprecated_member_use
  @override
  int get alpha => (_c.a * 255).round();
  // ignore: deprecated_member_use
  @override
  int get red => (_c.r * 255).round();
  // ignore: deprecated_member_use
  @override
  int get green => (_c.g * 255).round();
  // ignore: deprecated_member_use
  @override
  int get blue => (_c.b * 255).round();
  // ignore: deprecated_member_use
  @override
  double get opacity => _c.a;
  @override
  double computeLuminance() => _c.computeLuminance();
  @override
  Color withAlpha(int a) => _c.withAlpha(a);
  // ignore: deprecated_member_use
  @override
  Color withRed(int r) => _c.withRed(r);
  // ignore: deprecated_member_use
  @override
  Color withGreen(int g) => _c.withGreen(g);
  // ignore: deprecated_member_use
  @override
  Color withBlue(int b) => _c.withBlue(b);
  // ignore: deprecated_member_use
  @override
  Color withOpacity(double opacity) => _c.withValues(alpha: opacity);
  @override
  Color withValues({double? alpha, double? red, double? green, double? blue, ColorSpace? colorSpace}) =>
      _c.withValues(alpha: alpha, red: red, green: green, blue: blue, colorSpace: colorSpace);

  @override
  bool operator ==(Object other) => other is Color && other.toARGB32() == toARGB32() && other.colorSpace == colorSpace;
  @override
  int get hashCode => Object.hash(toARGB32(), colorSpace);
  @override
  String toString() => 'AppColor(${toARGB32().toRadixString(16)})';
}

class C {
  static const primary = AppColor(0xFF516B7A, 0xFF5E7B8B);
  static const primaryDark = AppColor(0xFF344955, 0xFF8FB0C2);
  static const primaryLight = AppColor(0xFFDCE7ED, 0xFF26343C);
  static const onPrimary = AppColor(0xFFFFFFFF, 0xFFFFFFFF);
  static const navBar = AppColor(0xFF344955, 0xFF1A2328);
  static const navActive = AppColor(0xFF4E6674, 0xFF34444E);
  static const navIcon = AppColor(0xFFC5D2D9, 0xFF9DAEB7);
  static const bg = AppColor(0xFFF7F9FA, 0xFF11181C);
  static const surface = AppColor(0xFFFFFFFF, 0xFF1B2429);
  static const surface2 = AppColor(0xFFF1F4F6, 0xFF243038);
  static const divider = AppColor(0xFFEEF2F4, 0xFF2C3840);
  static const text = AppColor(0xFF1D2930, 0xFFE6EDF0);
  static const text2 = AppColor(0xFF5F6B72, 0xFFA3B1B8);
  static const disabled = AppColor(0xFF9AA5AB, 0xFF5F6B72);
  static const success = AppColor(0xFF2E7D5B, 0xFF5BB48C);
  static const warning = AppColor(0xFFC78724, 0xFFE0A84A);
  static const warningBg = AppColor(0xFFF7E9D2, 0xFF3A2E1A);
  static const warningFg = AppColor(0xFF5E3C08, 0xFFF1D7A8);
  static const warnText = AppColor(0xFF8A5A12, 0xFFE3B36A);
  static const error = AppColor(0xFFB94A48, 0xFFE07B79);
  static const danger = AppColor(0xFFA23E3C, 0xFFE58A88);
  static const info = AppColor(0xFF3D6D8A, 0xFF7FB0CF);
  static const tile = AppColor(0xFFEAF0F3, 0xFF232E35);
  static const tileOff = AppColor(0xFFD9E2E7, 0xFF1E282E);
  static const seg = AppColor(0xFFE1E8EC, 0xFF2A363E);
  static const line = AppColor(0xFFE3E9EC, 0xFF2C3840);
  static const border = AppColor(0xFFC9D4DA, 0xFF3A4851);

  /// Véu sobre peças não selecionadas.
  static const veil = AppColor(0x8CDCE2E6, 0x9911181C);

  /// Chip/aba selecionado (fundo escuro no claro, claro no escuro).
  static const accent = AppColor(0xFF1D2930, 0xFFE6EDF0);
  static const onAccent = AppColor(0xFFFFFFFF, 0xFF11181C);
}

ThemeData buildTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF516B7A),
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: C.primary,
    onPrimary: C.onPrimary,
    surface: C.surface,
    onSurface: C.text,
    error: C.error,
  );
  final base = dark ? Typography.whiteMountainView : Typography.blackMountainView;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    canvasColor: C.surface,
    dividerColor: C.divider,
    textTheme: base.apply(bodyColor: C.text, displayColor: C.text),
    iconTheme: const IconThemeData(color: C.text),
    listTileTheme: const ListTileThemeData(iconColor: C.primaryDark, textColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      hintStyle: const TextStyle(color: C.text2),
      labelStyle: const TextStyle(color: C.text2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.primaryDark, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.primary,
        foregroundColor: C.onPrimary,
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
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: C.text2, width: 2),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.primary : null),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2C3840) : const Color(0xFF1D2930),
      contentTextStyle: const TextStyle(color: Color(0xFFF2F5F7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: C.surface, dragHandleColor: C.border),
  );
}
