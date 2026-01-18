import 'package:hive/hive.dart';

part 'shot_log.g.dart';

@HiveType(typeId: 2)
class ShotLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final int shotNumber;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool success;

  @HiveField(5)
  final String? photoPath;

  @HiveField(6)
  final String? errorMessage;

  @HiveField(7)
  final int? batteryLevel;

  @HiveField(8)
  final double? durationMinutes;

  ShotLog({
    required this.id,
    required this.projectId,
    required this.shotNumber,
    required this.timestamp,
    this.success = true,
    this.photoPath,
    this.errorMessage,
    this.batteryLevel,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'shotNumber': shotNumber,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'photoPath': photoPath,
      'errorMessage': errorMessage,
      'batteryLevel': batteryLevel,
      'durationMinutes': durationMinutes,
    };
  }

  factory ShotLog.fromJson(Map<String, dynamic> json) {
    return ShotLog(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      shotNumber: json['shotNumber'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      success: json['success'] as bool? ?? true,
      photoPath: json['photoPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
    );
  }
}
