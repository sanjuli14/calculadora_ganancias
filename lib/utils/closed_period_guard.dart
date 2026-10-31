import 'package:flutter/material.dart';
import '../services/database_service.dart';

// Ejecuta una operación que puede tocar un período cerrado. Si se rechaza,
// muestra el motivo y devuelve false.
Future<bool> guardClosedPeriod(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on ClosedPeriodException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    return false;
  }
}
