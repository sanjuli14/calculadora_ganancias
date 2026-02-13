import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0)
  String productName;

  @HiveField(1)
  double unitBuyPrice;

  @HiveField(2)
  double unitSellPrice;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  DateTime date;

  Sale({
    required this.productName,
    required this.unitBuyPrice,
    required this.unitSellPrice,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'unitBuyPrice': unitBuyPrice,
      'unitSellPrice': unitSellPrice,
      'quantity': quantity,
      'date': date.toIso8601String(),
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      productName: json['productName'],
      unitBuyPrice: json['unitBuyPrice'],
      unitSellPrice: json['unitSellPrice'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
    );
  }

  double get total => unitSellPrice * quantity;
  double get profit => (unitSellPrice - unitBuyPrice) * quantity;
}
