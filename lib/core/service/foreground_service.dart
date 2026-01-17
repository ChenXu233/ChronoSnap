import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final int _notificationId = 1;

  ForegroundService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

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
