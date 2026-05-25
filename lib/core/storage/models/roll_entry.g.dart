// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roll_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RollEntryAdapter extends TypeAdapter<RollEntry> {
  @override
  final typeId = 0;

  @override
  RollEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RollEntry(
      timestamp: fields[0] as DateTime,
      diceTypeIndex: (fields[1] as num).toInt(),
      diceCount: (fields[2] as num).toInt(),
      values: (fields[3] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, RollEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.diceTypeIndex)
      ..writeByte(2)
      ..write(obj.diceCount)
      ..writeByte(3)
      ..write(obj.values);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RollEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
