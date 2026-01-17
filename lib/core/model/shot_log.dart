import 'package:hive/hive.dart';

part 'shot_log.g.dart';

@HiveType(typeId: 2)
class ShotLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int batteryLevel;

  @HiveField(5)
  final bool isSuccess;

  @HiveField(6)
  final String? errorMessage;

  ShotLog({
    required this.id,
    required this.projectId,
    required this.filePath,
    required this.timestamp,
    required this.batteryLevel,
    this.isSuccess = true,
    this.errorMessage,
  });
}
