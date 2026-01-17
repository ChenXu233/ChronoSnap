import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check if all required permissions are granted
  Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await _getStorageStatus();
    final notificationStatus = await Permission.notification.status;

    return cameraStatus.isGranted &&
        storageStatus.isGranted &&
        notificationStatus.isGranted;
  }

  /// Request all required permissions
  Future<bool> requestPermissions() async {
    final results = await [
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ].request();

    return results.values.every((status) => status.isGranted);
  }

  /// Check and request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Check and request storage permission based on Android version
  Future<bool> requestStoragePermission() async {
    final status = await _getStorageStatus();
    if (status.isGranted) return true;

    // For Android 13+, we need media images permission
    if (await Permission.photos.request().isGranted) {
      return true;
    }

    // For older versions, request storage permission
    return (await Permission.storage.request()).isGranted;
  }

  /// Check and request notification permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    return (await Permission.notification.request()).isGranted;
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Get storage permission status based on Android version
  Future<PermissionStatus> _getStoragePermissionOld() async {
    return await Permission.storage.status;
  }

  Future<PermissionStatus> _getStorageStatus() async {
    // Check if we're on Android 13+
    return await Permission.storage.status;
  }
}
