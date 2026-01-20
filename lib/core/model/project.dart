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

  /// 高级时间表配置
  @HiveField(11)
  final bool? enableSchedule;

  @HiveField(12)
  final int? startHour;

  @HiveField(13)
  final int? endHour;

  @HiveField(14)
  final List<int>? selectedDays;

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
    this.enableSchedule = false,
    this.startHour,
    this.endHour,
    this.selectedDays,
  });

  /// 检查当前时间是否在拍摄时间范围内
  bool isInScheduleWindow() {
    if (enableSchedule != true) return true;
    if (startHour == null || endHour == null) return true;

    final now = DateTime.now();
    final currentHour = now.hour;
    final currentDay = now.weekday; // 1=Monday, 7=Sunday

    // 检查小时范围
    if (startHour! <= endHour!) {
      // 同一天，如 10:00 - 18:00
      if (currentHour < startHour! || currentHour >= endHour!) {
        return false;
      }
    } else {
      // 跨天，如 22:00 - 06:00
      if (currentHour < startHour! && currentHour >= endHour!) {
        return false;
      }
    }

    // 检查日期
    if (selectedDays != null && selectedDays!.isNotEmpty) {
      if (!selectedDays!.contains(currentDay)) {
        return false;
      }
    }

    return true;
  }

  /// 获取下一次可拍摄时间
  DateTime? getNextAvailableTime() {
    if (enableSchedule != true) return DateTime.now();

    final now = DateTime.now();
    final start = startHour ?? 0;
    final end = endHour ?? 23;
    final days = selectedDays;

    if (days == null || days.isEmpty) {
      // 每天都可以，只检查小时
      if (now.hour >= end) {
        return DateTime(now.year, now.month, now.day + 1, start);
      }
      return DateTime(now.year, now.month, now.day, start);
    }

    // 检查日期
    for (int i = 0; i < 7; i++) {
      final checkDay = (now.weekday + i - 1) % 7 + 1; // 转换到 1-7 范围
      if (days.contains(checkDay)) {
        if (i == 0) {
          // 今天
          if (now.hour < end) {
            final nextTime = DateTime(now.year, now.month, now.day, start);
            if (nextTime.isAfter(now)) {
              return nextTime;
            }
            return DateTime(now.year, now.month, now.day, end);
          }
        } else {
          // 未来的某天
          final targetDay = now.add(Duration(days: i));
          return DateTime(targetDay.year, targetDay.month, targetDay.day, start);
        }
      }
    }

    return null;
  }

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
