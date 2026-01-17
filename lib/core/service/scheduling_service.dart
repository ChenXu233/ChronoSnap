import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../model/project.dart';

class SchedulingService {
  Timer? _timer;
  Function(DateTime)? _onShotTime;
  Project? _currentProject;
  DateTime? _nextShotTime;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SchedulingService() {
    _initNotifications();
  }

  void _initNotifications() {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    _notificationsPlugin.initialize(settings);
  }

  Future<void> startScheduling(
    Project project,
    Function(DateTime) onShotTime,
  ) async {
    _currentProject = project;
    _onShotTime = onShotTime;

    // Schedule first shot immediately or after interval
    _nextShotTime = DateTime.now().add(
      Duration(seconds: project.intervalSeconds),
    );

    await _scheduleNextShot();
  }

  Future<void> _scheduleNextShot() async {
    if (_nextShotTime == null || _currentProject == null) return;

    final now = DateTime.now();
    final delay = _nextShotTime!.difference(now);

    if (delay.isNegative) {
      // Immediate execution
      _onShotTime?.call(_nextShotTime!);
      _scheduleNextShot();
      return;
    }

    // Cancel existing timer
    _timer?.cancel();

    _timer = Timer(delay, () {
      _onShotTime?.call(_nextShotTime!);
      _nextShotTime = _nextShotTime!.add(
        Duration(seconds: _currentProject!.intervalSeconds),
      );
      _scheduleNextShot();
    });

    // Show notification for next shot
    await _showNextShotNotification(delay.inMinutes);
  }

  Future<void> _showNextShotNotification(int minutesUntil) async {
    const androidDetails = AndroidNotificationDetails(
      'chrono_snap_channel',
      'ChronoSnap',
      channelDescription: 'Shows next shot time',
      importance: Importance.low,
      priority: Priority.low,
    );

    const notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'ChronoSnap',
      'Next shot in $minutesUntil minutes',
      notificationDetails,
    );
  }

  void stopScheduling() {
    _timer?.cancel();
    _timer = null;
    _currentProject = null;
    _nextShotTime = null;
    _onShotTime = null;
  }

  DateTime? get nextShotTime => _nextShotTime;
  bool get isScheduling => _timer != null;
}
