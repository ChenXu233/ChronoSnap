// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shot_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShotLogAdapter extends TypeAdapter<ShotLog> {
  @override
  final int typeId = 2;

  @override
  ShotLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShotLog(
      id: fields[0] as String,
      projectId: fields[1] as String,
      filePath: fields[2] as String,
      timestamp: fields[3] as DateTime,
      batteryLevel: fields[4] as int,
      isSuccess: fields[5] as bool,
      errorMessage: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShotLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.batteryLevel)
      ..writeByte(5)
      ..write(obj.isSuccess)
      ..writeByte(6)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShotLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
