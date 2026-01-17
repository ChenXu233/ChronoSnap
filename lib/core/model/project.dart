import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 0)
enum ProjectStatus {
  @HiveField(0)
  idle,
  @HiveField(1)
  running,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
}

@HiveType(typeId: 1)
class Project {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String storagePath;

  @HiveField(3)
  final int intervalSeconds;

  @HiveField(4)
  final int? totalShots;

  @HiveField(5)
  final int? durationMinutes;

  @HiveField(6)
  final String cameraConfigJson;

  @HiveField(7)
  final DateTime createdTime;

  @HiveField(8)
  final ProjectStatus status;

  @HiveField(9)
  int completedShots;

  @HiveField(10)
  DateTime? lastShotTime;

  Project({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.intervalSeconds,
    this.totalShots,
    this.durationMinutes,
    required this.cameraConfigJson,
    required this.createdTime,
    this.status = ProjectStatus.idle,
    this.completedShots = 0,
    this.lastShotTime,
  });

  bool get isCompleted =>
      totalShots != null && completedShots >= totalShots! ||
      durationMinutes != null &&
          lastShotTime != null &&
          DateTime.now().isAfter(
            lastShotTime!.add(Duration(minutes: durationMinutes!)),
          );

  bool get canStart =>
      status == ProjectStatus.idle || status == ProjectStatus.paused;
}
