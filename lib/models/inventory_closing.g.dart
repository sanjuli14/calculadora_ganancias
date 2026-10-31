// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_closing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryClosingAdapter extends TypeAdapter<InventoryClosing> {
  @override
  final int typeId = 10;

  @override
  InventoryClosing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryClosing(
      periodStart: fields[0] as DateTime?,
      closedAt: fields[1] as DateTime,
      salesCount: fields[2] as int,
      unitsSold: fields[3] as int,
      revenue: fields[4] as double,
      cogs: fields[5] as double,
      shrinkageCost: fields[6] as double,
      expenses: fields[7] as double,
      purchases: fields[8] as double,
      commissions: fields[9] as double,
      creditSold: fields[10] as double,
      creditCollected: fields[11] as double,
      creditProfitCollected: fields[12] as double,
      creditOutstanding: fields[13] as double,
      stockUnits: fields[14] as int,
      stockCost: fields[15] as double,
      stockValue: fields[16] as double,
      surplusUnits: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryClosing obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.periodStart)
      ..writeByte(1)
      ..write(obj.closedAt)
      ..writeByte(2)
      ..write(obj.salesCount)
      ..writeByte(3)
      ..write(obj.unitsSold)
      ..writeByte(4)
      ..write(obj.revenue)
      ..writeByte(5)
      ..write(obj.cogs)
      ..writeByte(6)
      ..write(obj.shrinkageCost)
      ..writeByte(7)
      ..write(obj.expenses)
      ..writeByte(8)
      ..write(obj.purchases)
      ..writeByte(9)
      ..write(obj.commissions)
      ..writeByte(10)
      ..write(obj.creditSold)
      ..writeByte(11)
      ..write(obj.creditCollected)
      ..writeByte(12)
      ..write(obj.creditProfitCollected)
      ..writeByte(13)
      ..write(obj.creditOutstanding)
      ..writeByte(14)
      ..write(obj.stockUnits)
      ..writeByte(15)
      ..write(obj.stockCost)
      ..writeByte(16)
      ..write(obj.stockValue)
      ..writeByte(17)
      ..write(obj.surplusUnits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryClosingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
