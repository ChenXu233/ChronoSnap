import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../model/camera_config.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  CameraConfig? _appliedConfig;

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

  /// Windows 平台的模拟相机初始化
  Future<void> initializeMockCamera() async {
    _isInitialized = true;
  }

  /// 应用相机配置（对焦、曝光、白平衡锁定）
  Future<void> applyCameraConfig(CameraConfig config) async {
    if (!_isInitialized || _controller == null) return;

    _appliedConfig = config;

    try {
      // 1. 对焦锁定
      if (config.lockFocus) {
        await _lockFocus();
      } else {
        await _unlockFocus();
      }

      // 2. 曝光锁定
      if (config.lockExposure) {
        await _lockExposure(config.exposureCompensation);
      } else {
        await _unlockExposure();
      }

      // 3. 白平衡锁定
      if (!config.autoWhiteBalance) {
        await _lockWhiteBalance();
      } else {
        await _unlockWhiteBalance();
      }
    } catch (e) {
      // 如果平台不支持，忽略错误并继续
      debugPrint('Camera config apply error: $e');
    }
  }

  /// 锁定对焦到当前位置
  Future<void> _lockFocus() async {
    if (_controller == null) return;
    try {
      await _controller!.setFocusMode(FocusMode.locked);
    } catch (e) {
      // 部分设备可能不支持
      debugPrint('Lock focus error: $e');
    }
  }

  /// 释放对焦锁定（回到自动对焦）
  Future<void> _unlockFocus() async {
    if (_controller == null) return;
    try {
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Unlock focus error: $e');
    }
  }

  /// 锁定曝光
  Future<void> _lockExposure([int? exposureCompensation]) async {
    if (_controller == null) return;
    try {
      // 设置曝光模式为锁定
      await _controller!.setExposureMode(ExposureMode.locked);

      // 注意：camera 插件新版本不直接支持曝光补偿设置
      // 如需精确控制曝光，需要通过 Camera2 原生 API 实现
    } catch (e) {
      debugPrint('Lock exposure error: $e');
    }
  }

  /// 释放曝光锁定（回到自动曝光）
  Future<void> _unlockExposure() async {
    if (_controller == null) return;
    try {
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('Unlock exposure error: $e');
    }
  }

  /// 锁定白平衡
  /// 注意：camera 插件目前不支持白平衡锁定
  /// 后续需要通过 Camera2 原生 API 实现
  Future<void> _lockWhiteBalance() async {
    // camera 插件暂不支持白平衡锁定
    // 留待后续 Camera2 原生实现
    debugPrint('White balance lock not supported in camera plugin');
  }

  /// 释放白平衡锁定
  Future<void> _unlockWhiteBalance() async {
    // camera 插件暂不支持白平衡锁定
  }

  /// 重新应用配置（在每次拍照前调用，确保参数被锁定）
  Future<void> reapplyConfig() async {
    if (_appliedConfig != null) {
      await applyCameraConfig(_appliedConfig!);
    }
  }

  Future<String> takePicture(String projectName, int shotIndex) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    // 拍照前重新应用配置，确保参数锁定
    await reapplyConfig();

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

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _appliedConfig = null;
  }

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  CameraConfig? get appliedConfig => _appliedConfig;
}
