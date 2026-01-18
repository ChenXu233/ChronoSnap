import 'package:flutter/services.dart';

/// Camera2 原生 API 通道服务
/// 通过 MethodChannel 与 Android 原生 Camera2 代码通信
class Camera2Service {
  static const _channel = MethodChannel('com.chrono_snap/camera2');

  bool _isInitialized = false;
  String? _currentCameraId;
  int _currentExposureCompensation = 0;
  double _currentFocusDistance = 0.0;
  bool _isWhiteBalanceLocked = false;

  bool get isInitialized => _isInitialized;

  /// 获取可用的相机列表
  Future<List<CameraInfo>> getAvailableCameras() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAvailableCameras');

      if (result == null) return [];

      return result.map((camera) {
        return CameraInfo(
          id: camera['id'] as String,
          name: camera['name'] as String,
          lensDirection: camera['lensDirection'] as String,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 打开相机
  Future<bool> openCamera(String cameraId) async {
    try {
      final result = await _channel.invokeMethod<bool>('openCamera', {
        'cameraId': cameraId,
      });
      _currentCameraId = cameraId;
      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// 锁定对焦到指定距离
  /// @param focusDistance 对焦距离，范围 0.0 ~ 10.0
  ///   - 0.0 表示无穷远
  ///   - 值越大越近（微距）
  Future<bool> lockFocus(double focusDistance) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod<bool>('lockFocus', {
        'focusDistance': focusDistance,
      });
      _currentFocusDistance = focusDistance;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 锁定曝光并设置曝光补偿
  /// @param exposureCompensation 曝光补偿值
  Future<bool> lockExposure(int exposureCompensation) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod<bool>('lockExposure', {
        'exposureCompensation': exposureCompensation,
      });
      _currentExposureCompensation = exposureCompensation;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 解锁曝光（回到自动曝光）
  Future<bool> unlockExposure() async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod<bool>('unlockExposure');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 锁定白平衡
  Future<bool> lockWhiteBalance() async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod<bool>('lockWhiteBalance');
      _isWhiteBalanceLocked = result ?? false;
      return _isWhiteBalanceLocked;
    } catch (e) {
      return false;
    }
  }

  /// 解锁白平衡（回到自动白平衡）
  Future<bool> unlockWhiteBalance() async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod<bool>('unlockWhiteBalance');
      _isWhiteBalanceLocked = !(result ?? false);
      return !_isWhiteBalanceLocked;
    } catch (e) {
      return false;
    }
  }

  /// 获取曝光补偿范围
  Future<ExposureCompensationRange> getExposureCompensationRange() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getExposureCompensationRange',
      );

      if (result == null) {
        return ExposureCompensationRange(min: 0, max: 0);
      }

      return ExposureCompensationRange(
        min: result['min'] as int,
        max: result['max'] as int,
      );
    } catch (e) {
      return ExposureCompensationRange(min: 0, max: 0);
    }
  }

  /// 关闭相机
  Future<void> closeCamera() async {
    try {
      await _channel.invokeMethod<bool>('closeCamera');
      _isInitialized = false;
      _currentCameraId = null;
    } catch (e) {
      // 忽略错误
    }
  }

  /// 释放资源
  void dispose() {
    closeCamera();
  }
}

/// 相机信息
class CameraInfo {
  final String id;
  final String name;
  final String lensDirection;

  CameraInfo({
    required this.id,
    required this.name,
    required this.lensDirection,
  });
}

/// 曝光补偿范围
class ExposureCompensationRange {
  final int min;
  final int max;

  ExposureCompensationRange({required this.min, required this.max});

  bool contains(int value) => value >= min && value <= max;
}

/// 单例访问
final camera2Service = Camera2Service();
