import 'package:intl/intl.dart';

const String currencyCode = 'CUP';

final NumberFormat _currencyFormat =
    NumberFormat.currency(locale: 'es', symbol: 'CUP ', decimalDigits: 2);

final NumberFormat _usdFormat =
    NumberFormat.currency(locale: 'es', symbol: 'USD ', decimalDigits: 2);

String formatMoney(double value) => _currencyFormat.format(value);

String formatUsd(double value) => _usdFormat.format(value);

String formatMoneyCompact(double value) {
  if (value >= 1000000) return 'CUP ${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return 'CUP ${(value / 1000).toStringAsFixed(1)}k';
  return _currencyFormat.format(value);
}

String formatUsdCompact(double value) {
  if (value >= 1000000) return 'USD ${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return 'USD ${(value / 1000).toStringAsFixed(1)}k';
  return _usdFormat.format(value);
}

String formatCents(double value) {
  final abs = value.abs();
  final isWhole = (abs - abs.roundToDouble()).abs() < 0.000001;
  return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
