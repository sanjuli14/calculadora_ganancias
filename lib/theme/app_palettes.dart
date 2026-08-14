import 'package:flutter/material.dart';

// Modos de visualización de la app.
enum AppThemeMode { light, dark, highContrast }

// Paleta de colores de la app. Cada paleta define los colores de marca y a
// partir de ellos se generan los neutros y suaves para cada modo.
class AppPalette {
  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color accentDark;
  final Color turquoise;

  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentDark,
    required this.turquoise,
  });
}

// Paletas predefinidas para que el usuario elija.
const List<AppPalette> appPalettes = [
  AppPalette(
    id: 'ocean',
    name: 'Océano',
    primary: Color(0xFF0F2E5E),
    primaryDark: Color(0xFF091E3F),
    primaryLight: Color(0xFF1B3F78),
    accent: Color(0xFF0E9F6E),
    accentDark: Color(0xFF0B7D55),
    turquoise: Color(0xFF14B8A6),
  ),
  AppPalette(
    id: 'emerald',
    name: 'Esmeralda',
    primary: Color(0xFF065F46),
    primaryDark: Color(0xFF04402E),
    primaryLight: Color(0xFF0B7D55),
    accent: Color(0xFF0E9F6E),
    accentDark: Color(0xFF0B7D55),
    turquoise: Color(0xFF14B8A6),
  ),
  AppPalette(
    id: 'vino',
    name: 'Vino',
    primary: Color(0xFF7F1D1D),
    primaryDark: Color(0xFF581010),
    primaryLight: Color(0xFF9F3131),
    accent: Color(0xFFB45309),
    accentDark: Color(0xFF92400E),
    turquoise: Color(0xFF0F766E),
  ),
  AppPalette(
    id: 'violeta',
    name: 'Violeta',
    primary: Color(0xFF4C1D95),
    primaryDark: Color(0xFF2E1065),
    primaryLight: Color(0xFF6D28D9),
    accent: Color(0xFF0E9F6E),
    accentDark: Color(0xFF0B7D55),
    turquoise: Color(0xFF0891B2),
  ),
  AppPalette(
    id: 'turquesa',
    name: 'Turquesa',
    primary: Color(0xFF134E4A),
    primaryDark: Color(0xFF0B322F),
    primaryLight: Color(0xFF0F766E),
    accent: Color(0xFF0E9F6E),
    accentDark: Color(0xFF0B7D55),
    turquoise: Color(0xFF06B6D4),
  ),
];

AppPalette paletteById(String id) {
  for (final p in appPalettes) {
    if (p.id == id) return p;
  }
  return appPalettes.first;
}

// Utilidades para derivar colores a partir de una paleta.
Color _lighten(Color c, double amount) {
  return Color.lerp(c, Colors.white, amount)!;
}

Color _darken(Color c, double amount) {
  return Color.lerp(c, Colors.black, amount)!;
}

// Genera los colores de la app para un modo y paleta dados.
// Devuelve el mismo mapa de nombres que AppColors.
Map<String, Color> buildColors(AppThemeMode mode, AppPalette p) {
  final light = mode == AppThemeMode.light;
  final highContrast = mode == AppThemeMode.highContrast;

  if (highContrast) {
    return {
      'navy': _darken(p.primary, 0.35),
      'navyDark': Colors.black,
      'navyLight': p.primary,
      'emerald': _darken(p.accent, 0.25),
      'emeraldDark': Colors.black,
      'turquoise': _darken(p.turquoise, 0.2),
      'background': Colors.white,
      'surface': Colors.white,
      'textPrimary': Colors.black,
      'textSecondary': const Color(0xFF1F2937),
      'border': Colors.black,
      'success': _darken(p.accent, 0.25),
      'warning': const Color(0xFFB45309),
      'danger': const Color(0xFF9F1239),
      'info': const Color(0xFF1D4ED8),
      'emeraldSoft': Colors.white,
      'turquoiseSoft': Colors.white,
      'navySoft': Colors.white,
      'warningSoft': Colors.white,
      'dangerSoft': Colors.white,
    };
  }

  if (!light) {
    // Modo oscuro: fondos muy oscuros, texto claro, acentos más vivos.
    return {
      'navy': p.primaryLight,
      'navyDark': Colors.black,
      'navyLight': _lighten(p.primaryLight, 0.25),
      'emerald': _lighten(p.accent, 0.15),
      'emeraldDark': p.accentDark,
      'turquoise': _lighten(p.turquoise, 0.1),
      'background': const Color(0xFF0B1220),
      'surface': const Color(0xFF16202F),
      'textPrimary': const Color(0xFFEAF1FB),
      'textSecondary': const Color(0xFF9FB0C5),
      'border': const Color(0xFF2A3950),
      'success': _lighten(p.accent, 0.15),
      'warning': const Color(0xFFFBBF24),
      'danger': const Color(0xFFFB7185),
      'info': const Color(0xFF60A5FA),
      'emeraldSoft': const Color(0xFF0F2A24),
      'turquoiseSoft': const Color(0xFF0B2B2E),
      'navySoft': const Color(0xFF1A2A47),
      'warningSoft': const Color(0xFF3A2E14),
      'dangerSoft': const Color(0xFF3A1A26),
    };
  }

  // Modo claro.
  return {
    'navy': p.primary,
    'navyDark': p.primaryDark,
    'navyLight': p.primaryLight,
    'emerald': p.accent,
    'emeraldDark': p.accentDark,
    'turquoise': p.turquoise,
    'background': const Color(0xFFF4F7FC),
    'surface': const Color(0xFFFFFFFF),
    'textPrimary': const Color(0xFF102A43),
    'textSecondary': const Color(0xFF627D98),
    'border': const Color(0xFFE3EAF3),
    'success': p.accent,
    'warning': const Color(0xFFF59E0B),
    'danger': const Color(0xFFE11D48),
    'info': const Color(0xFF2563EB),
    'emeraldSoft': const Color(0xFFE7F7F1),
    'turquoiseSoft': const Color(0xFFE0F5F3),
    'navySoft': _lighten(p.primary, 0.88),
    'warningSoft': const Color(0xFFFEF4E6),
    'dangerSoft': const Color(0xFFFDEBEF),
  };
}
