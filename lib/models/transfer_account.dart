import 'package:hive/hive.dart';

part 'transfer_account.g.dart';

@HiveType(typeId: 5)
class TransferAccount extends HiveObject {
  @HiveField(0)
  String alias;

  @HiveField(1)
  String bankName;

  @HiveField(2)
  String cardNumber;

  @HiveField(3)
  String qrImagePath;

  @HiveField(4)
  bool isDefault;

  TransferAccount({
    required this.alias,
    required this.bankName,
    required this.cardNumber,
    required this.qrImagePath,
    this.isDefault = false,
  });
}
