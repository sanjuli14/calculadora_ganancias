import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcular_ganancias/screens/calculator_screen.dart';

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('Muestra la operacion completa en secuencia y el resultado en vivo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    await tap(tester, '8');
    await tap(tester, '+');
    await tap(tester, '5');

    expect(find.text('8 + 5'), findsOneWidget);
    expect(find.text('= 13'), findsOneWidget);
  });

  testWidgets('El resultado se fija sin necesidad de tocar igual', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    await tap(tester, '1');
    await tap(tester, '2');
    await tap(tester, '×');
    await tap(tester, '4');

    expect(find.text('= 48'), findsOneWidget);

    await tap(tester, '=');
    expect(find.text('= 48'), findsNothing);
    expect(find.text('48'), findsOneWidget);
  });

  testWidgets('Operaciones encadenadas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    await tap(tester, '2');
    await tap(tester, '×');
    await tap(tester, '3');
    await tap(tester, '+');
    await tap(tester, '4');
    await tap(tester, '=');

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('Empieza una nueva operacion despues del igual', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    await tap(tester, '9');
    await tap(tester, '+');
    await tap(tester, '1');
    await tap(tester, '=');

    await tap(tester, '7');
    expect(find.text('10'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data == '7' && w.style?.fontSize == 52,
      ),
      findsOneWidget,
    );
  });
}