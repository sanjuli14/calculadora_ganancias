import 'package:hive/hive.dart';
import 'payment.dart';

part 'debt.g.dart';

@HiveType(typeId: 3)
class Debt extends HiveObject {
  @HiveField(0)
  String customerName;

  @HiveField(1)
  String productName;

  @HiveField(2)
  double unitPrice;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double unitCost;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? note;

  @HiveField(7)
  List<Payment> payments;

  Debt({
    required this.customerName,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.unitCost,
    required this.date,
    this.note,
    List<Payment>? payments,
  }) : payments = payments ?? [];

  double get total => unitPrice * quantity;

  double get paid => payments.fold(0.0, (sum, p) => sum + p.amount);

  double get balance => total - paid;

  bool get isPaid => balance <= 0.001;

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unitCost': unitCost,
      'date': date.toIso8601String(),
      'note': note,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      customerName: json['customerName'] as String,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      unitCost: (json['unitCost'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      payments: (json['payments'] as List? ?? [])
          .map((i) => Payment.fromJson(i))
          .toList(),
    );
  }
}
