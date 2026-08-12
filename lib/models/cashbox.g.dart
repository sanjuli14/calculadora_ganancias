// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbox.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashCountAdapter extends TypeAdapter<CashCount> {
  @override
  final int typeId = 2;

  @override
  CashCount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashCount(
      date: fields[0] as DateTime,
      denominations: (fields[1] as Map).cast<String, int>(),
      expectedAmount: fields[2] as double?,
      note: fields[3] as String?,
      currencyCode: (fields[4] as String?) ?? 'CUP',
    );
  }

  @override
  void write(BinaryWriter writer, CashCount obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.denominations)
      ..writeByte(2)
      ..write(obj.expectedAmount)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.currencyCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashCountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
