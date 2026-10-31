import 'dart:convert';
import 'dart:io';

import 'package:calcular_ganancias/models/debt.dart';
import 'package:calcular_ganancias/models/expense.dart';
import 'package:calcular_ganancias/models/inventory_closing.dart';
import 'package:calcular_ganancias/models/payment.dart';
import 'package:calcular_ganancias/models/product.dart';
import 'package:calcular_ganancias/models/sale.dart';
import 'package:calcular_ganancias/models/shrinkage.dart';
import 'package:calcular_ganancias/services/database_service.dart';
import 'package:calcular_ganancias/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  final db = DatabaseService();

  Sale sale(DateTime date, {int quantity = 1}) => Sale(
    productName: 'Arroz',
    unitBuyPrice: 60,
    unitSellPrice: 100,
    quantity: quantity,
    date: date,
  );

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('closing_test');
    Hive.init(dir.path);
    await db.openBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  setUp(() async {
    await db.productsBox.clear();
    await db.salesBox.clear();
    await db.expensesBox.clear();
    await db.shrinkagesBox.clear();
    await db.debtsBox.clear();
    await db.closingsBox.clear();
    await db.setManualLastClosing(null);
    await db.addProduct(
      Product(name: 'Arroz', buyPrice: 60, sellPrice: 100, stock: 10),
    );
  });

  test('la fecha manual excluye lo anterior, incluso del día previo', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 5));
    await db.salesBox.add(sale(start.subtract(const Duration(hours: 1))));
    await db.salesBox.add(
      sale(start.add(const Duration(hours: 1)), quantity: 2),
    );
    await db.setManualLastClosing(start);

    final period = db.computeCurrentPeriod();

    expect(period.periodStart, start);
    expect(period.salesCount, 1);
    expect(period.revenue, 200);
    expect(period.grossProfit, 80);
  });

  test('sin cierres el período incluye todos los datos', () async {
    await db.salesBox.add(sale(DateTime(2021)));
    expect(db.computeCurrentPeriod().salesCount, 1);
    expect(db.currentPeriodStart, isNull);
  });

  test('cerrar guarda la foto y empieza un período en cero', () async {
    await db.salesBox.add(
      sale(DateTime.now().subtract(const Duration(minutes: 1)), quantity: 3),
    );
    await db.addExpense(
      Expense(
        name: 'Ana',
        description: 'Luz',
        amount: 20,
        date: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );

    final closing = await db.closeInventory();

    expect(closing.revenue, 300);
    expect(closing.netProfit, 100);
    expect(closing.stockUnits, 10);
    expect(db.currentPeriodStart, closing.closedAt);
    final next = db.computeCurrentPeriod();
    expect(next.salesCount, 0);
    expect(next.netProfit, 0);
    expect(next.stockUnits, 10, reason: 'el stock pasa al período nuevo');
  });

  test('el conteo convierte faltantes en merma y suma sobrantes', () async {
    await db.addProduct(
      Product(name: 'Sal', buyPrice: 10, sellPrice: 20, stock: 5),
    );
    final arroz = db.productsBox.values.first;
    final sal = db.productsBox.values.last;

    final closing = await db.closeInventory(
      counted: {arroz.key: 8, sal.key: 7},
    );

    expect(arroz.stock, 8);
    expect(sal.stock, 7);
    expect(closing.shrinkageCost, 120);
    expect(closing.surplusUnits, 2);
    expect(closing.netProfit, -120);
    expect(
      db.shrinkagesBox.values.single.reason,
      Shrinkage.closingAdjustmentReason,
    );
    expect(closing.stockUnits, 15);
  });

  test('un período cerrado no se puede cambiar', () async {
    final key = await db.salesBox.add(
      sale(DateTime.now().subtract(const Duration(minutes: 1))),
    );
    await db.closeInventory();

    await expectLater(
      db.deleteSale(key),
      throwsA(isA<ClosedPeriodException>()),
    );
    await expectLater(
      db.addExpense(
        Expense(
          name: 'Ana',
          description: 'Atrasado',
          amount: 5,
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
      throwsA(isA<ClosedPeriodException>()),
    );
    expect(db.salesBox.length, 1);
    expect(db.expensesBox.length, 0);
    expect(db.productsBox.values.first.stock, 10);
  });

  test('la fecha manual no bloquea registros anteriores', () async {
    final key = await db.salesBox.add(sale(DateTime(2021)));
    await db.setManualLastClosing(DateTime.now());
    await db.deleteSale(key);
    expect(db.salesBox.length, 0);
  });

  test('la fecha manual no se cambia tras un cierre real', () async {
    await db.closeInventory();
    expect(db.setManualLastClosing(DateTime(2022)), throwsStateError);
  });

  test('la ganancia de un cobro de fiado es proporcional', () async {
    final now = DateTime.now();
    await db.debtsBox.add(
      Debt(
        customerName: 'Luis',
        productName: 'Arroz',
        unitPrice: 100,
        quantity: 2,
        unitCost: 60,
        date: now.subtract(const Duration(days: 40)),
        payments: [
          Payment(
            amount: 50,
            date: now.subtract(const Duration(days: 1)),
            method: 'efectivo',
          ),
        ],
      ),
    );
    await db.setManualLastClosing(now.subtract(const Duration(days: 10)));

    final period = db.computeCurrentPeriod();

    expect(period.creditSold, 0);
    expect(period.creditCollected, 50);
    expect(period.creditProfitCollected, closeTo(20, 0.001));
    expect(period.creditOutstanding, 150);
  });

  test('con el reloj atrasado no se registran ventas ni cobros', () async {
    await db.closeInventory();
    final debtKey = await db.debtsBox.add(
      Debt(
        customerName: 'Luis',
        productName: 'Arroz',
        unitPrice: 100,
        quantity: 1,
        unitCost: 60,
        date: DateTime.now(),
      ),
    );

    await expectLater(
      db.registerSale(sale(DateTime.now().subtract(const Duration(days: 1)))),
      throwsA(isA<ClosedPeriodException>()),
    );
    expect(db.salesBox.length, 0);
    expect(db.productsBox.values.first.stock, 10);

    // Con el reloj bien, el cobro sí se registra.
    await db.addDebtPayment(debtKey, 10, 'efectivo');
    expect(db.debtsBox.get(debtKey)!.paid, 10);
  });

  test('las comisiones incluyen las de los cobros de fiado', () async {
    final now = DateTime.now();
    await db.salesBox.add(
      sale(now.subtract(const Duration(minutes: 1)))..commissionAmount = 3,
    );
    await db.debtsBox.add(
      Debt(
        customerName: 'Luis',
        productName: 'Arroz',
        unitPrice: 100,
        quantity: 1,
        unitCost: 60,
        date: now.subtract(const Duration(minutes: 1)),
        payments: [
          Payment(
            amount: 50,
            date: now.subtract(const Duration(minutes: 1)),
            method: 'transferencia',
            commissionAmount: 2,
          ),
        ],
      ),
    );

    expect(db.computeCurrentPeriod().commissions, 5);
  });

  test('los sobrantes de un cierre no pasan al siguiente', () async {
    final arroz = db.productsBox.values.first;
    final first = await db.closeInventory(counted: {arroz.key: 12});
    final second = await db.closeInventory();

    expect(first.surplusUnits, 2);
    expect(second.surplusUnits, 0);
  });

  group('rangos de fechas', () {
    test('Hoy no incluye ayer', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await db.salesBox.add(sale(today.subtract(const Duration(minutes: 1))));
      await db.salesBox.add(sale(today));
      await db.salesBox.add(sale(endOfDay(now)));

      expect(db.getTodaySales().length, 2);
    });

    test('un día concreto no incluye los días vecinos', () async {
      final day = DateTime(2025, 3, 15);
      await db.salesBox.add(sale(DateTime(2025, 3, 14, 23, 59)));
      await db.salesBox.add(sale(DateTime(2025, 3, 15, 12)));
      await db.salesBox.add(sale(DateTime(2025, 3, 16)));

      expect(db.getSalesForDay(day).length, 1);
    });

    test('Mes abarca su último día y no el mes anterior', () async {
      final now = DateTime.now();
      final first = DateTime(now.year, now.month, 1);
      await db.salesBox.add(sale(first.subtract(const Duration(minutes: 1))));
      await db.salesBox.add(sale(first));
      await db.salesBox.add(sale(DateTime(now.year, now.month + 1, 0, 23, 59)));

      expect(db.getMonthlySales().length, 2);
    });

    test('Semana va del último viernes hasta hoy', () async {
      final now = DateTime.now();
      final days = (now.weekday - DateTime.friday) % 7;
      final friday = DateTime(now.year, now.month, now.day - days);
      await db.salesBox.add(sale(friday.subtract(const Duration(minutes: 1))));
      await db.salesBox.add(sale(friday));
      await db.salesBox.add(sale(now));

      expect(db.getWeeklySalesCustom(DateTime.friday).length, 2);
    });

    test('gastos y mermas respetan los límites del rango', () async {
      final start = DateTime(2025, 3, 15);
      final end = endOfDay(start);
      Expense expense(DateTime date) =>
          Expense(name: 'Ana', description: '', amount: 10, date: date);
      Shrinkage shrinkage(DateTime date) =>
          Shrinkage(date: date, productName: 'Arroz', quantity: 1, unitCost: 5);
      await db.addExpense(expense(DateTime(2025, 3, 14, 23)));
      await db.addExpense(expense(DateTime(2025, 3, 15, 8)));
      await db.addExpense(expense(DateTime(2025, 3, 16, 1)));
      await db.shrinkagesBox.add(shrinkage(DateTime(2025, 3, 14, 23)));
      await db.shrinkagesBox.add(shrinkage(DateTime(2025, 3, 15, 8)));

      expect(db.getExpensesBetween(start, end), 10);
      expect(db.getShrinkageCostBetween(start, end), 5);
    });
  });

  test('el cierre sobrevive a la copia JSON', () async {
    await db.salesBox.add(
      sale(DateTime.now().subtract(const Duration(minutes: 1))),
    );
    final closing = await db.closeInventory();

    final copy = InventoryClosing.fromJson(
      jsonDecode(jsonEncode(closing.toJson())) as Map<String, dynamic>,
    );

    expect(copy.closedAt, closing.closedAt);
    expect(copy.periodStart, isNull);
    expect(copy.netProfit, closing.netProfit);
  });
}
