import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 6)
class Expense extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  Expense({
    required this.name,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
