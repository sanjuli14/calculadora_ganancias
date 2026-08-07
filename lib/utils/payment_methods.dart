import 'package:flutter/material.dart';

class PaymentMethod {
  static const String cash = 'efectivo';
  static const String transfer = 'transferencia';
  static const String credit = 'credito';

  static const List<String> all = [cash, transfer, credit];

  static String label(String method) {
    switch (method) {
      case transfer:
        return 'Transferencia';
      case credit:
        return 'A Crédito (Fiado)';
      default:
        return 'Efectivo';
    }
  }

  static String shortLabel(String method) {
    switch (method) {
      case transfer:
        return 'Transf.';
      case credit:
        return 'Crédito';
      default:
        return 'Efectivo';
    }
  }

  static IconData icon(String method) {
    switch (method) {
      case transfer:
        return Icons.account_balance_outlined;
      case credit:
        return Icons.handshake_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}
