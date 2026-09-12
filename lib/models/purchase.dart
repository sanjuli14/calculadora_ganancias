import 'package:hive/hive.dart';

part 'purchase.g.dart';

/// Un artículo dentro de una compra/lote.
@HiveType(typeId: 7)
class PurchaseItem extends HiveObject {
  @HiveField(0)
  String productName;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitCost;

  @HiveField(3)
  String? productId;

  PurchaseItem({
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.productId,
  });

  double get total => quantity * unitCost;

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'productId': productId,
    };
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      productName: (json['productName'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      productId: json['productId'] as String?,
    );
  }
}

/// Compra/lote: registro histórico e inmutable de mercancía entrante.
/// A diferencia del producto, nunca se borra ni edita: queda como auditoría.
@HiveType(typeId: 8)
class Purchase extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String supplierName;

  @HiveField(2)
  List<PurchaseItem> items;

  @HiveField(3)
  double totalCost;

  Purchase({
    required this.date,
    this.supplierName = '',
    List<PurchaseItem>? items,
    this.totalCost = 0,
  }) : items = items ?? [];

  int get totalUnits => items.fold(0, (s, i) => s + i.quantity);

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'supplierName': supplierName,
      'items': items.map((i) => i.toJson()).toList(),
      'totalCost': totalCost,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      date: DateTime.parse(json['date'] as String),
      supplierName: (json['supplierName'] ?? '').toString(),
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((i) => PurchaseItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Costo promedio ponderado de un producto según sus compras registradas:
/// suma(costo unitario × cantidad) / suma(cantidad). Devuelve null si el
/// producto no aparece en el libro de compras.
double? weightedAveragePurchaseCost(
  Iterable<Purchase> purchases,
  String productName,
) {
  double totalCost = 0;
  int totalQty = 0;
  for (final purchase in purchases) {
    for (final item in purchase.items) {
      if (item.productName == productName) {
        totalCost += item.unitCost * item.quantity;
        totalQty += item.quantity;
      }
    }
  }
  if (totalQty <= 0) return null;
  return totalCost / totalQty;
}