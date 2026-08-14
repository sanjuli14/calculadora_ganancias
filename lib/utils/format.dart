import 'package:intl/intl.dart';

// Moneda activa (configurable en Personalización). Cambiar esta variable y
// llamar setCurrencyCode() actualiza todos los formatos de la app.
const List<String> supportedCurrencyCodes = ['CUP', 'USD', 'EUR'];

String _activeCurrencyCode = 'CUP';
NumberFormat? _currencyFormat;
NumberFormat? _usdFormat;

String get activeCurrencyCode => _activeCurrencyCode;

String currencySymbol(String code) {
  switch (code) {
    case 'USD':
      return 'USD ';
    case 'EUR':
      return 'EUR ';
    case 'CUP':
    default:
      return 'CUP ';
  }
}

void setCurrencyCode(String code) {
  if (!supportedCurrencyCodes.contains(code)) return;
  _activeCurrencyCode = code;
  _currencyFormat = null;
}

NumberFormat _moneyFormat() {
  _currencyFormat ??= NumberFormat.currency(
    locale: 'es',
    symbol: currencySymbol(_activeCurrencyCode),
    decimalDigits: 2,
  );
  return _currencyFormat!;
}

NumberFormat _usdNumberFormat() {
  _usdFormat ??= NumberFormat.currency(
    locale: 'es',
    symbol: 'USD ',
    decimalDigits: 2,
  );
  return _usdFormat!;
}

String formatMoney(double value) => _moneyFormat().format(value);

String formatUsd(double value) => _usdNumberFormat().format(value);

String formatMoneyCompact(double value) {
  final symbol = currencySymbol(_activeCurrencyCode);
  if (value >= 1000000)
    return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '$symbol${(value / 1000).toStringAsFixed(1)}k';
  return _moneyFormat().format(value);
}

String formatUsdCompact(double value) {
  if (value >= 1000000) return 'USD ${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return 'USD ${(value / 1000).toStringAsFixed(1)}k';
  return _usdNumberFormat().format(value);
}

String formatCents(double value) {
  final abs = value.abs();
  final isWhole = (abs - abs.roundToDouble()).abs() < 0.000001;
  return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
