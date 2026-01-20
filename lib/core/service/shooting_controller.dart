import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import '../model/project.dart';
import '../model/shot_log.dart';
import '../repository/project_repository.dart';
import 'camera_service.dart';
import 'foreground_service.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class ShootingController {
  final Project project;
  final CameraService cameraService;
  final ForegroundService foregroundService;
  final ProjectRepository repository;

  Timer? _timer;
  int _completedShots = 0;
  DateTime? _nextShotTime;
  DateTime? _startTime;
  int _shotIndex = 0;
  bool _isRunning = false;

  final Battery _battery = Battery();
  int _currentBattery = 100;
  StreamSubscription? _batterySubscription;

  // Callbacks for UI updates
  Function(int completedShots, DateTime? nextShotTime, int battery)?
      onProgressUpdate;
  Function()? onShotTaken;
  Function()? onCompleted;
  Function(String error)? onError;

  ShootingController({
    required this.project,
    required this.cameraService,
    required this.foregroundService,
    required this.repository,
  }) {
    _completedShots = project.completedShots;
    _shotIndex = _completedShots;
  }

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _startTime = DateTime.now();

    // Initialize battery monitoring
    _startBatteryMonitoring();

    // Initialize repository
    await repository.initialize();

    // Show initial notification
    await foregroundService.updateProgress(
      projectName: project.name,
      completedShots: _completedShots,
      totalShots: project.totalShots,
      nextShotTime: DateTime.now().add(Duration(seconds: project.intervalSeconds)),
      batteryLevel: _currentBattery,
    );

    // Schedule first shot
    await _scheduleNextShot();
  }

  Future<void> _startBatteryMonitoring() async {
    // Get initial battery level
    _currentBattery = await _battery.batteryLevel;

    // Battery Plus v6 uses stream for battery changes
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      // Update battery level when state changes
      _battery.batteryLevel.then((level) {
        _currentBattery = level;
        _updateNotification();
      });
    });
  }

  Future<void> _scheduleNextShot() async {
    if (!_isRunning) return;

    // Check completion conditions
    if (_checkCompletion()) {
      await stop();
      onCompleted?.call();
      return;
    }

    // Calculate next shot time
    final now = DateTime.now();
    _nextShotTime = now.add(Duration(seconds: project.intervalSeconds));

    // Update UI
    onProgressUpdate?.call(_completedShots, _nextShotTime, _currentBattery);
    await _updateNotification();

    // Schedule timer
    final delay = _nextShotTime!.difference(now);
    _timer = Timer(delay, () async {
      await _executeShot();
    });
  }

  Future<void> _executeShot() async {
    try {
      // Take the picture
      final filePath = await cameraService.takePicture(
        project.name,
        _shotIndex,
      );

      // Record the shot
      final shotLog = ShotLog(
        id: _uuid.v4(),
        projectId: project.id,
        shotNumber: _shotIndex,
        photoPath: filePath,
        timestamp: DateTime.now(),
        batteryLevel: _currentBattery,
        success: true,
      );

      await repository.saveShotLog(shotLog);

      // Update counters
      _completedShots++;
      _shotIndex++;

      // Update project status
      await repository.updateProjectStatus(
        project.id,
        ProjectStatus.running,
        completedShots: _completedShots,
        lastShotTime: DateTime.now(),
      );

      // Notify listeners
      onShotTaken?.call();
      onProgressUpdate?.call(_completedShots, null, _currentBattery);

      // Schedule next shot
      await _scheduleNextShot();
    } catch (e) {
      // Record failed shot
      final shotLog = ShotLog(
        id: _uuid.v4(),
        projectId: project.id,
        shotNumber: _shotIndex,
        photoPath: null,
        timestamp: DateTime.now(),
        batteryLevel: _currentBattery,
        success: false,
        errorMessage: e.toString(),
      );

      await repository.saveShotLog(shotLog);
      onError?.call(e.toString());
    }
  }

  bool _checkCompletion() {
    // Check total shots limit
    if (project.totalShots != null && _completedShots >= project.totalShots!) {
      return true;
    }

    // Check duration limit
    if (project.durationMinutes != null && _startTime != null) {
      final endTime = _startTime!.add(Duration(minutes: project.durationMinutes!));
      if (DateTime.now().isAfter(endTime)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _updateNotification() async {
    await foregroundService.updateProgress(
      projectName: project.name,
      completedShots: _completedShots,
      totalShots: project.totalShots,
      nextShotTime: _nextShotTime,
      batteryLevel: _currentBattery,
    );
  }

  Future<void> stop() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // Update project status
    await repository.updateProjectStatus(
      project.id,
      ProjectStatus.idle,
      completedShots: _completedShots,
      lastShotTime: DateTime.now(),
    );

    // Cancel battery monitoring
    await _batterySubscription?.cancel();
    _batterySubscription = null;

    // Cancel notification
    await foregroundService.cancelNotification();
  }

  void dispose() {
    stop();
    cameraService.dispose();
  }

  int get completedShots => _completedShots;
  DateTime? get nextShotTime => _nextShotTime;
  bool get isRunning => _isRunning;
}
