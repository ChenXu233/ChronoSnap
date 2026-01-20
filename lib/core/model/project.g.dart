// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 1;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      name: fields[1] as String,
      storagePath: fields[2] as String,
      intervalSeconds: fields[3] as int,
      totalShots: fields[4] as int?,
      durationMinutes: fields[5] as int?,
      cameraConfigJson: fields[6] as String,
      createdTime: fields[7] as DateTime,
      status: fields[8] as ProjectStatus,
      completedShots: fields[9] as int,
      lastShotTime: fields[10] as DateTime?,
      enableSchedule: fields[11] as bool?,
      startHour: fields[12] as int?,
      endHour: fields[13] as int?,
      selectedDays: (fields[14] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.storagePath)
      ..writeByte(3)
      ..write(obj.intervalSeconds)
      ..writeByte(4)
      ..write(obj.totalShots)
      ..writeByte(5)
      ..write(obj.durationMinutes)
      ..writeByte(6)
      ..write(obj.cameraConfigJson)
      ..writeByte(7)
      ..write(obj.createdTime)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.completedShots)
      ..writeByte(10)
      ..write(obj.lastShotTime)
      ..writeByte(11)
      ..write(obj.enableSchedule)
      ..writeByte(12)
      ..write(obj.startHour)
      ..writeByte(13)
      ..write(obj.endHour)
      ..writeByte(14)
      ..write(obj.selectedDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProjectStatusAdapter extends TypeAdapter<ProjectStatus> {
  @override
  final int typeId = 0;

  @override
  ProjectStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProjectStatus.idle;
      case 1:
        return ProjectStatus.running;
      case 2:
        return ProjectStatus.paused;
      case 3:
        return ProjectStatus.completed;
      default:
        return ProjectStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, ProjectStatus obj) {
    switch (obj) {
      case ProjectStatus.idle:
        writer.writeByte(0);
        break;
      case ProjectStatus.running:
        writer.writeByte(1);
        break;
      case ProjectStatus.paused:
        writer.writeByte(2);
        break;
      case ProjectStatus.completed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
