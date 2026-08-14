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

  @HiveField(5)
  String paymentMethod;

  @HiveField(6)
  double? commissionAmount;

  @HiveField(7)
  double? exchangeRate;

  Sale({
    required this.productName,
    required this.unitBuyPrice,
    required this.unitSellPrice,
    required this.quantity,
    required this.date,
    this.paymentMethod = 'efectivo',
    this.commissionAmount,
    this.exchangeRate,
  });

  bool get isOwnExpense => paymentMethod == 'gasto_propio';
  double get total => isOwnExpense ? 0 : unitSellPrice * quantity;
  double get profit =>
      isOwnExpense ? 0 : (unitSellPrice - unitBuyPrice) * quantity;
  double get ownExpenseCost => isOwnExpense ? unitBuyPrice * quantity : 0;
  double get commission => commissionAmount ?? 0;
  double get netReceived => total - commission;
  double get usdAmount =>
      exchangeRate != null && exchangeRate! > 0 ? total / exchangeRate! : 0;

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'unitBuyPrice': unitBuyPrice,
      'unitSellPrice': unitSellPrice,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'commissionAmount': commissionAmount,
      'exchangeRate': exchangeRate,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      productName: json['productName'],
      unitBuyPrice: json['unitBuyPrice'],
      unitSellPrice: json['unitSellPrice'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
      paymentMethod: json['paymentMethod'] as String? ?? 'efectivo',
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
    );
  }
}
