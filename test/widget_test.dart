import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcular_ganancias/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding muestra las pantallas y el boton Siguiente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Tu inventario al día'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
