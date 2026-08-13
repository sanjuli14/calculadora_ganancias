import 'package:flutter_test/flutter_test.dart';

import 'package:calcular_ganancias/models/expense.dart';

void main() {
  test('Expense toJson/fromJson round-trip conserva los datos', () {
    final original = Expense(
      name: 'Pedro',
      description: 'Gasolina',
      amount: 150.5,
      date: DateTime(2026, 8, 13, 10, 30),
    );

    final restored = Expense.fromJson(original.toJson());

    expect(restored.name, original.name);
    expect(restored.description, original.description);
    expect(restored.amount, original.amount);
    expect(restored.date, original.date);
  });
}