import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../model/project.dart';

class ForegroundService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final int _notificationId = 1;

  ForegroundService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> showNotification({
    required String title,
    required String content,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chrono_snap_foreground',
      'ChronoSnap Shooting',
      channelDescription: 'Shows shooting progress',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      _notificationId,
      title,
      content,
      notificationDetails,
    );
  }

  Future<void> updateProgress({
    required String projectName,
    required int completedShots,
    required int? totalShots,
    required DateTime? nextShotTime,
    required int batteryLevel,
  }) async {
    String content = 'Completed: $completedShots';
    if (totalShots != null) {
      content += '/$totalShots';
    }

    if (nextShotTime != null) {
      final minutes = nextShotTime.difference(DateTime.now()).inMinutes;
      content += '\nNext: ${minutes}min';
    }

    content += '\nBattery: $batteryLevel%';

    await showNotification(
      title: 'ChronoSnap - $projectName',
      content: content,
    );
  }

  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(_notificationId);
  }
}

/// Service manager for handling foreground service lifecycle
class ServiceManager {
  /// Check if there are running projects that need to be restored
  static Future<List<Project>> getRunningProjects(
    List<Project> allProjects,
  ) async {
    return allProjects.where((p) => p.status == ProjectStatus.running).toList();
  }

  /// Calculate delay until next valid shooting window
  static Duration? getNextShootingDelay(Project project) {
    if (!project.enableSchedule) {
      return const Duration(seconds: 0);
    }

    final nextTime = project.getNextAvailableTime();
    if (nextTime == null) return null;

    final delay = nextTime.difference(DateTime.now());
    return delay.isNegative ? null : delay;
  }
}
