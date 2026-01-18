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
      shotNumber: fields[2] as int,
      timestamp: fields[3] as DateTime,
      success: fields[4] as bool,
      photoPath: fields[5] as String?,
      errorMessage: fields[6] as String?,
      batteryLevel: fields[7] as int?,
      durationMinutes: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ShotLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.shotNumber)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.success)
      ..writeByte(5)
      ..write(obj.photoPath)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.batteryLevel)
      ..writeByte(8)
      ..write(obj.durationMinutes);
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
