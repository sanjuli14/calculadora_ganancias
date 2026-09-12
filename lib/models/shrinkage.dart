import 'package:hive/hive.dart';

part 'shrinkage.g.dart';

/// Merma / ajuste de inventario: mercancía perdida que afecta el balance.
@HiveType(typeId: 9)
class Shrinkage extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String productName;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double unitCost;

  @HiveField(4)
  String reason;

  @HiveField(5)
  String? productId;

  static const List<String> reasons = [
    'Vencimiento',
    'Rotura',
    'Daño',
    'Robo',
    'Otro',
  ];

  Shrinkage({
    required this.date,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.reason = 'Otro',
    this.productId,
  });

  /// Valor económico real perdido (cantidad × costo de adquisición).
  double get cost => quantity * unitCost;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'reason': reason,
      'productId': productId,
    };
  }

  factory Shrinkage.fromJson(Map<String, dynamic> json) {
    return Shrinkage(
      date: DateTime.parse(json['date'] as String),
      productName: (json['productName'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      reason: (json['reason'] ?? 'Otro').toString(),
      productId: json['productId'] as String?,
    );
  }
}