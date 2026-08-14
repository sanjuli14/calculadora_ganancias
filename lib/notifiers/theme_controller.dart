import 'package:flutter/foundation.dart';

import '../services/database_service.dart';
import '../theme/app_palettes.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Controla los ajustes de apariencia (modo, paleta, moneda) y los persiste
// en la box de metadatos. Al cambiar, re-aplica los colores estáticos y avisa
// a la UI para que se reconstruya.
class ThemeController extends ChangeNotifier {
  final DatabaseService db;

  ThemeController(this.db);

  late AppThemeMode _mode;
  late AppPalette _palette;

  AppThemeMode get mode => _mode;
  AppPalette get palette => _palette;

  Future<void> init() async {
    _mode = db.appearanceMode;
    _palette = db.appearancePalette;
    AppColors.apply(_mode, _palette);
    setCurrencyCode(db.appearanceCurrency);
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppColors.apply(_mode, _palette);
    await db.setAppearance(mode: mode);
    notifyListeners();
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette.id == palette.id) return;
    _palette = palette;
    AppColors.apply(_mode, _palette);
    await db.setAppearance(paletteId: palette.id);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (activeCurrencyCode == code) return;
    setCurrencyCode(code);
    await db.setAppearance(currency: code);
    notifyListeners();
  }

  String get currencySymbolLabel => currencySymbol(activeCurrencyCode).trim();
}
