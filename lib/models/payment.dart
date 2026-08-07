import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 4)
class Payment extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String method;

  @HiveField(3)
  double? commissionAmount;

  Payment({
    required this.amount,
    required this.date,
    required this.method,
    this.commissionAmount,
  });

  double get netReceived => amount - (commissionAmount ?? 0);

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'commissionAmount': commissionAmount,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      method: json['method'] as String,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
    );
  }
}
