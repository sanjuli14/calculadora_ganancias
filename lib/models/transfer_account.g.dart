// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferAccountAdapter extends TypeAdapter<TransferAccount> {
  @override
  final int typeId = 5;

  @override
  TransferAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferAccount(
      alias: fields[0] as String,
      bankName: fields[1] as String,
      cardNumber: fields[2] as String,
      qrImagePath: fields[3] as String,
      isDefault: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransferAccount obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.alias)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.cardNumber)
      ..writeByte(3)
      ..write(obj.qrImagePath)
      ..writeByte(4)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
