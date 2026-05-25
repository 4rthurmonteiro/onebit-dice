// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomPresetAdapter extends TypeAdapter<CustomPreset> {
  @override
  final typeId = 1;

  @override
  CustomPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      diceTypeIndex: (fields[2] as num).toInt(),
      diceCount: (fields[3] as num).toInt(),
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomPreset obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.diceTypeIndex)
      ..writeByte(3)
      ..write(obj.diceCount)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
