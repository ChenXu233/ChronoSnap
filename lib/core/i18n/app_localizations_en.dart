// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChronoSnap';

  @override
  String get projectList => 'Projects';

  @override
  String get createProject => 'Create Project';

  @override
  String get projectName => 'Project Name';

  @override
  String get projectNameHint => 'Enter project name';

  @override
  String get shootingInterval => 'Shooting Interval';

  @override
  String intervalSeconds(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String intervalMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String intervalHours(Object hours) {
    return '$hours hours';
  }

  @override
  String get totalShots => 'Total Shots';

  @override
  String get totalShotsHint => 'Number of photos to take';

  @override
  String get duration => 'Duration';

  @override
  String durationMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get cameraSettings => 'Camera Settings';

  @override
  String get lockFocus => 'Lock Focus';

  @override
  String get lockExposure => 'Lock Exposure';

  @override
  String get autoWhiteBalance => 'Auto White Balance';

  @override
  String get startShooting => 'Start Shooting';

  @override
  String get stopShooting => 'Stop';

  @override
  String get projectRunning => 'Running';

  @override
  String get projectCompleted => 'Completed';

  @override
  String get projectIdle => 'Idle';

  @override
  String completedShots(Object count) {
    return 'Completed: $count';
  }

  @override
  String nextShot(Object time) {
    return 'Next shot: $time';
  }

  @override
  String currentBattery(Object level) {
    return 'Battery: $level%';
  }

  @override
  String get deleteProject => 'Delete Project';

  @override
  String get confirmDelete => 'Are you sure you want to delete this project?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get cameraPermissionRequired => 'Camera permission is required';

  @override
  String get storagePermissionRequired => 'Storage permission is required';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get tapToCreate => 'Tap + to create a project';
}
