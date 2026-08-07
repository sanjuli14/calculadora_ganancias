import 'package:hive/hive.dart';

part 'cashbox.g.dart';

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

  CashCount({
    required this.date,
    required this.denominations,
    this.expectedAmount,
    this.note,
  });

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
    };
  }

  factory CashCount.fromJson(Map<String, dynamic> json) {
    return CashCount(
      date: DateTime.parse(json['date'] as String),
      denominations: Map<String, int>.from(json['denominations'] as Map? ?? {}),
      expectedAmount: (json['expectedAmount'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}
