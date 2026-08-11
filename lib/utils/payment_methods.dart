import 'package:flutter/material.dart';

class PaymentMethod {
  static const String cash = 'efectivo';
  static const String transfer = 'transferencia';
  static const String credit = 'credito';
  static const String dollar = 'dolar';
  static const String ownExpense = 'gasto_propio';

  static const List<String> all = [cash, transfer, credit, dollar, ownExpense];

  static String label(String method) {
    switch (method) {
      case transfer:
        return 'Transferencia';
      case credit:
        return 'A Crédito (Fiado)';
      case dollar:
        return 'Dólar';
      case ownExpense:
        return 'Gasto propio';
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
      case dollar:
        return 'USD';
      case ownExpense:
        return 'Gasto';
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
      case dollar:
        return Icons.attach_money_outlined;
      case ownExpense:
        return Icons.person_outline;
      default:
        return Icons.payments_outlined;
    }
  }
}
