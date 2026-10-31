import 'package:hive/hive.dart';

part 'inventory_closing.g.dart';

/// Cierre de inventario: foto fija de los números de un período. Una vez
/// guardado no cambia, aunque cambien los productos o sus precios.
///
/// También se usa sin guardar para mostrar los números del período en curso.
@HiveType(typeId: 10)
class InventoryClosing extends HiveObject {
  // Null cuando el período empieza desde el inicio de los datos.
  @HiveField(0)
  DateTime? periodStart;

  @HiveField(1)
  DateTime closedAt;

  @HiveField(2)
  int salesCount;

  @HiveField(3)
  int unitsSold;

  @HiveField(4)
  double revenue;

  @HiveField(5)
  double cogs;

  @HiveField(6)
  double shrinkageCost;

  @HiveField(7)
  double expenses;

  @HiveField(8)
  double purchases;

  @HiveField(9)
  double commissions;

  // Fiados: se llevan aparte porque no se registran como ventas.
  @HiveField(10)
  double creditSold;

  @HiveField(11)
  double creditCollected;

  @HiveField(12)
  double creditProfitCollected;

  @HiveField(13)
  double creditOutstanding;

  @HiveField(14)
  int stockUnits;

  @HiveField(15)
  double stockCost;

  @HiveField(16)
  double stockValue;

  // Unidades de más encontradas en el conteo físico.
  @HiveField(17)
  int surplusUnits;

  InventoryClosing({
    this.periodStart,
    required this.closedAt,
    this.salesCount = 0,
    this.unitsSold = 0,
    this.revenue = 0,
    this.cogs = 0,
    this.shrinkageCost = 0,
    this.expenses = 0,
    this.purchases = 0,
    this.commissions = 0,
    this.creditSold = 0,
    this.creditCollected = 0,
    this.creditProfitCollected = 0,
    this.creditOutstanding = 0,
    this.stockUnits = 0,
    this.stockCost = 0,
    this.stockValue = 0,
    this.surplusUnits = 0,
  });

  double get grossProfit => revenue - cogs;

  // Misma fórmula que Reportes: ganancia bruta - mermas - gastos.
  double get netProfit => grossProfit - shrinkageCost - expenses;

  Map<String, dynamic> toJson() {
    return {
      'periodStart': periodStart?.toIso8601String(),
      'closedAt': closedAt.toIso8601String(),
      'salesCount': salesCount,
      'unitsSold': unitsSold,
      'revenue': revenue,
      'cogs': cogs,
      'shrinkageCost': shrinkageCost,
      'expenses': expenses,
      'purchases': purchases,
      'commissions': commissions,
      'creditSold': creditSold,
      'creditCollected': creditCollected,
      'creditProfitCollected': creditProfitCollected,
      'creditOutstanding': creditOutstanding,
      'stockUnits': stockUnits,
      'stockCost': stockCost,
      'stockValue': stockValue,
      'surplusUnits': surplusUnits,
    };
  }

  factory InventoryClosing.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    int integer(String key) => (json[key] as num?)?.toInt() ?? 0;
    final start = json['periodStart'] as String?;
    return InventoryClosing(
      periodStart: start == null ? null : DateTime.parse(start),
      closedAt: DateTime.parse(json['closedAt'] as String),
      salesCount: integer('salesCount'),
      unitsSold: integer('unitsSold'),
      revenue: number('revenue'),
      cogs: number('cogs'),
      shrinkageCost: number('shrinkageCost'),
      expenses: number('expenses'),
      purchases: number('purchases'),
      commissions: number('commissions'),
      creditSold: number('creditSold'),
      creditCollected: number('creditCollected'),
      creditProfitCollected: number('creditProfitCollected'),
      creditOutstanding: number('creditOutstanding'),
      stockUnits: integer('stockUnits'),
      stockCost: number('stockCost'),
      stockValue: number('stockValue'),
      surplusUnits: integer('surplusUnits'),
    );
  }
}
