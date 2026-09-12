// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shrinkage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShrinkageAdapter extends TypeAdapter<Shrinkage> {
  @override
  final int typeId = 9;

  @override
  Shrinkage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shrinkage(
      date: fields[0] as DateTime,
      productName: fields[1] as String,
      quantity: fields[2] as int,
      unitCost: fields[3] as double,
      reason: fields[4] as String,
      productId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Shrinkage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unitCost)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.productId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShrinkageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
