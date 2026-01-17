import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../model/camera_config.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  Future<void> initializeCamera(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  void applyCameraConfig(CameraConfig config) async {
    if (!_isInitialized || _controller == null) return;

    // Lock focus if enabled
    if (config.lockFocus && config.focusDistance != null) {
      // Note: Manual focus requires Camera2 API on Android
      // This is a simplified implementation
    }

    // Lock exposure if enabled
    if (config.lockExposure) {
      // Exposure lock is not directly supported in camera plugin
      // Would require platform-specific code
    }

    // Auto white balance
    if (!config.autoWhiteBalance) {
      // White balance lock is not directly supported in camera plugin
    }
  }

  Future<String> takePicture(String projectName, int shotIndex) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/ChronoSnap/$projectName');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    final timestamp = DateTime.now();
    final fileName =
        '${projectName}_${timestamp.toIso8601String().replaceAll(':', '-').replaceAll('.', '_')}_${shotIndex.toString().padLeft(3, '0')}.jpg';
    final filePath = '${projectDir.path}/$fileName';

    final XFile imageFile = await _controller!.takePicture();
    await imageFile.saveTo(filePath);

    return filePath;
  }

  void lockExposure() {
    // Platform-specific implementation needed for true exposure lock
  }

  void lockFocus() {
    // Platform-specific implementation needed for true focus lock
  }

  void unlockExposure() {
    // Reset exposure to auto
  }

  void unlockFocus() {
    // Reset focus to auto
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
}
