import 'package:flutter_test/flutter_test.dart';

import 'package:calcular_ganancias/models/purchase.dart';
import 'package:calcular_ganancias/models/shrinkage.dart';
import 'package:calcular_ganancias/models/product.dart';
import 'package:calcular_ganancias/models/sale.dart';
import 'package:calcular_ganancias/models/debt.dart';

void main() {
  test('Purchase toJson/fromJson round-trip conserva el lote', () {
    final original = Purchase(
      date: DateTime(2026, 9, 12, 9, 15),
      supplierName: 'Mercado Central',
      items: [
        PurchaseItem(productName: 'Café', quantity: 5, unitCost: 120),
        PurchaseItem(productName: 'Arroz', quantity: 10, unitCost: 45),
      ],
      totalCost: 1050,
    );

    final restored = Purchase.fromJson(original.toJson());

    expect(restored.date, original.date);
    expect(restored.supplierName, original.supplierName);
    expect(restored.items.length, 2);
    expect(restored.items[0].productName, 'Café');
    expect(restored.items[0].quantity, 5);
    expect(restored.items[0].unitCost, 120);
    expect(restored.items[0].total, 600);
    expect(restored.totalCost, 1050);
    expect(restored.totalUnits, 15);
  });

  test('PurchaseItem.total calcula costo por cantidad', () {
    final item = PurchaseItem(productName: 'Leche', quantity: 3, unitCost: 70);
    expect(item.total, 210);
  });

  test('Shrinkage toJson/fromJson round-trip conserva la merma', () {
    final original = Shrinkage(
      date: DateTime(2026, 9, 12, 18, 0),
      productName: 'Yogurt',
      quantity: 2,
      unitCost: 60,
      reason: 'Vencimiento',
    );

    final restored = Shrinkage.fromJson(original.toJson());

    expect(restored.date, original.date);
    expect(restored.productName, 'Yogurt');
    expect(restored.quantity, 2);
    expect(restored.unitCost, 60);
    expect(restored.reason, 'Vencimiento');
    expect(restored.cost, 120);
  });

  test('weightedAveragePurchaseCost pondera por cantidad comprada', () {
    final purchases = [
      Purchase(
        date: DateTime(2026, 9, 1),
        items: [
          PurchaseItem(productName: 'Café', quantity: 10, unitCost: 100),
          PurchaseItem(productName: 'Arroz', quantity: 5, unitCost: 40),
        ],
      ),
      Purchase(
        date: DateTime(2026, 9, 10),
        items: [PurchaseItem(productName: 'Café', quantity: 5, unitCost: 120)],
      ),
    ];

    // (10 × 100 + 5 × 120) / 15 = 106.66…
    final avg = weightedAveragePurchaseCost(purchases, 'Café');
    expect(avg, isNotNull);
    expect(avg, closeTo(106.6667, 0.0001));
  });

  test('weightedAveragePurchaseCost devuelve null si no hubo compras', () {
    final purchases = [
      Purchase(
        date: DateTime(2026, 9, 1),
        items: [PurchaseItem(productName: 'Café', quantity: 5, unitCost: 100)],
      ),
    ];

    expect(weightedAveragePurchaseCost(purchases, 'Leche'), isNull);
  });

  test('productId sobrevive al round-trip JSON de todos los modelos', () {
    final product = Product(
      name: 'Café',
      buyPrice: 100,
      sellPrice: 150,
      stock: 3,
      productId: 'p_123',
    );
    expect(Product.fromJson(product.toJson()).productId, 'p_123');
    expect(Product.fromJson(product.toJson()).name, 'Café');

    final sale = Sale(
      productName: 'Café',
      productId: 'p_123',
      unitBuyPrice: 100,
      unitSellPrice: 150,
      quantity: 2,
      date: DateTime(2026, 9, 12),
    );
    expect(Sale.fromJson(sale.toJson()).productId, 'p_123');

    final purchase = Purchase(
      date: DateTime(2026, 9, 12),
      items: [
        PurchaseItem(
          productName: 'Café',
          productId: 'p_123',
          quantity: 5,
          unitCost: 100,
        ),
      ],
    );
    final restoredPurchase = Purchase.fromJson(purchase.toJson());
    expect(restoredPurchase.items.single.productId, 'p_123');

    final shrinkage = Shrinkage(
      date: DateTime(2026, 9, 12),
      productName: 'Café',
      productId: 'p_123',
      quantity: 1,
      unitCost: 100,
    );
    expect(Shrinkage.fromJson(shrinkage.toJson()).productId, 'p_123');

    final debt = Debt(
      customerName: 'Ana',
      productName: 'Café',
      productId: 'p_123',
      unitPrice: 150,
      quantity: 2,
      unitCost: 100,
      date: DateTime(2026, 9, 12),
    );
    expect(Debt.fromJson(debt.toJson()).productId, 'p_123');
  });

  test('Product.ensureId asigna un ID estable solo una vez', () {
    final product = Product(name: 'Arroz', buyPrice: 45, sellPrice: 60);
    final id = product.ensureId();
    expect(id, isNotEmpty);
    expect(product.ensureId(), id);
  });
}