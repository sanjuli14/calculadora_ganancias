import 'package:flutter/material.dart';

import 'app_palettes.dart';

// Colores de la app. Al pasar de paleta/modo se reasignan con apply(), así que
// la UI se reconstruye y lee los valores nuevos.
class AppColors {
  AppColors._();

  static Color navy = const Color(0xFF0F2E5E);
  static Color navyDark = const Color(0xFF091E3F);
  static Color navyLight = const Color(0xFF1B3F78);

  static Color emerald = const Color(0xFF0E9F6E);
  static Color emeraldDark = const Color(0xFF0B7D55);
  static Color turquoise = const Color(0xFF14B8A6);

  static Color background = const Color(0xFFF4F7FC);
  static Color surface = const Color(0xFFFFFFFF);
  static Color textPrimary = const Color(0xFF102A43);
  static Color textSecondary = const Color(0xFF627D98);
  static Color border = const Color(0xFFE3EAF3);

  static Color success = const Color(0xFF0E9F6E);
  static Color warning = const Color(0xFFF59E0B);
  static Color danger = const Color(0xFFE11D48);
  static Color info = const Color(0xFF2563EB);

  static Color emeraldSoft = const Color(0xFFE7F7F1);
  static Color turquoiseSoft = const Color(0xFFE0F5F3);
  static Color navySoft = const Color(0xFFE8EEF8);
  static Color warningSoft = const Color(0xFFFEF4E6);
  static Color dangerSoft = const Color(0xFFFDEBEF);

  // Aplica la paleta + modo elegidos a todos los colores estáticos.
  static void apply(AppThemeMode mode, AppPalette palette) {
    final colors = buildColors(mode, palette);
    navy = colors['navy']!;
    navyDark = colors['navyDark']!;
    navyLight = colors['navyLight']!;
    emerald = colors['emerald']!;
    emeraldDark = colors['emeraldDark']!;
    turquoise = colors['turquoise']!;
    background = colors['background']!;
    surface = colors['surface']!;
    textPrimary = colors['textPrimary']!;
    textSecondary = colors['textSecondary']!;
    border = colors['border']!;
    success = colors['success']!;
    warning = colors['warning']!;
    danger = colors['danger']!;
    info = colors['info']!;
    emeraldSoft = colors['emeraldSoft']!;
    turquoiseSoft = colors['turquoiseSoft']!;
    navySoft = colors['navySoft']!;
    warningSoft = colors['warningSoft']!;
    dangerSoft = colors['dangerSoft']!;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeMode themeModeOf(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.highContrast:
      case AppThemeMode.light:
        return ThemeMode.light;
    }
  }

  static ThemeData forMode(AppThemeMode mode) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: mode == AppThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.navy,
            brightness: mode == AppThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
            primary: AppColors.navy,
            secondary: AppColors.emerald,
            tertiary: AppColors.turquoise,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            error: AppColors.danger,
          ).copyWith(
            outline: AppColors.border,
            surfaceContainerHighest: AppColors.surface,
          ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.navy, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.navy,
        suffixIconColor: AppColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          foregroundColor: AppColors.navy,
          side: BorderSide(color: AppColors.navy, width: 1.4),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyDark,
        contentTextStyle: const TextStyle(fontFamily: 'Poppins'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navySoft,
        labelStyle: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.navy),
    );
  }
}
