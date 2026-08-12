import 'package:hive/hive.dart';

part 'cashbox.g.dart';

enum CashCurrency { cup, usd }

@HiveType(typeId: 2)
class CashCount extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  Map<String, int> denominations;

  @HiveField(2)
  double? expectedAmount;

  @HiveField(3)
  String? note;

  @HiveField(4)
  String currencyCode;

  CashCount({
    required this.date,
    required this.denominations,
    this.expectedAmount,
    this.note,
    this.currencyCode = 'CUP',
  });

  CashCurrency get currency =>
      currencyCode == 'USD' ? CashCurrency.usd : CashCurrency.cup;

  String get currencyLabel => currency == CashCurrency.usd ? 'USD' : 'CUP';

  double get total {
    double sum = 0;
    denominations.forEach((denom, count) {
      sum += (double.tryParse(denom) ?? 0) * count;
    });
    return sum;
  }

  double? get difference {
    if (expectedAmount == null) return null;
    return total - expectedAmount!;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'denominations': denominations,
      'expectedAmount': expectedAmount,
      'note': note,
      'currencyCode': currencyCode,
    };
  }

  factory CashCount.fromJson(Map<String, dynamic> json) {
    final code = (json['currencyCode'] as String?) ?? 'CUP';
    return CashCount(
      date: DateTime.parse(json['date'] as String),
      denominations: Map<String, int>.from(json['denominations'] as Map? ?? {}),
      expectedAmount: (json['expectedAmount'] as num?)?.toDouble(),
      note: json['note'] as String?,
      currencyCode: code == 'USD' ? 'USD' : 'CUP',
    );
  }
}
