import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/project.dart';
import '../../core/i18n/app_localizations.dart';
import '../project/project_notifier.dart';
import '../monitoring/monitoring_screen.dart';
import 'package:camera/camera.dart';

class CameraPreviewScreen extends ConsumerStatefulWidget {
  final Project project;

  const CameraPreviewScreen({super.key, required this.project});

  @override
  ConsumerState<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends ConsumerState<CameraPreviewScreen> {
  List<CameraDescription> _cameras = [];
  CameraDescription? _selectedCamera;
  bool _isInitializing = false;
  String? _errorMessage;
  bool _isInitializedWithoutCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // 尝试获取可用相机（所有平台）
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        // 没有检测到相机，直接显示占位符，不转圈
        _isInitializedWithoutCamera = true;
        _isInitializing = false;
        return;
      }

      // 如果只有一个相机，直接初始化；多个相机选第一个
      _selectedCamera ??= _cameras.first;

      final cameraService = ref.read(cameraServiceProvider);
      await cameraService.initializeCamera(_selectedCamera!);

    } catch (e) {
      // 初始化失败
      _isInitializedWithoutCamera = true;
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// 切换到指定相机
  Future<void> _switchCamera(CameraDescription camera) async {
    if (camera == _selectedCamera) return;

    final cameraService = ref.read(cameraServiceProvider);
    cameraService.dispose();

    setState(() {
      _selectedCamera = camera;
      _isInitializing = true;
    });

    try {
      await cameraService.initializeCamera(camera);
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// 显示相机选择对话框
  void _showCameraSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择相机',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ..._cameras.map((camera) {
                final isSelected = camera == _selectedCamera;
                return ListTile(
                  leading: Icon(
                    camera.lensDirection == CameraLensDirection.back
                        ? Icons.camera_rear
                        : camera.lensDirection == CameraLensDirection.front
                            ? Icons.camera_front
                            : Icons.videocam,
                  ),
                  title: Text(camera.name),
                  subtitle: Text(_getCameraDirectionText(camera)),
                  selected: isSelected,
                  selectedTileColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  onTap: () {
                    Navigator.pop(context);
                    _switchCamera(camera);
                  },
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCameraDirectionText(CameraDescription camera) {
    switch (camera.lensDirection) {
      case CameraLensDirection.back:
        return '后置相机';
      case CameraLensDirection.front:
        return '前置相机';
      case CameraLensDirection.external:
        return '外置相机';
      default:
        return '未知';
    }
  }

  @override
  void dispose() {
    try {
      ref.read(cameraServiceProvider).dispose();
    } catch (e) {
      // 忽略 dispose 时的异常
    }
    super.dispose();
  }

  Future<void> _startShooting() async {
    final cameraService = ref.read(cameraServiceProvider);

    if (!cameraService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    // Update project status
    final repository = ref.read(projectRepositoryProvider);
    await repository.initialize();
    await repository.updateProjectStatus(
      widget.project.id,
      ProjectStatus.running,
      completedShots: 0,
      lastShotTime: DateTime.now(),
    );

    // Start foreground service notification
    final foregroundService = ref.read(foregroundServiceProvider);
    await foregroundService.showNotification(
      title: 'ChronoSnap - ${widget.project.name}',
      content: 'Starting capture...',
    );

    // Navigate to monitoring screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MonitoringScreen(project: widget.project),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive experience
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview Layer
          _isInitializing
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _errorMessage != null
              ? _ErrorState(message: _errorMessage!, onRetry: _initializeCamera)
              : cameraService.controller != null
              ? Center(child: CameraPreview(cameraService.controller!))
              : (Platform.isWindows || _isInitializedWithoutCamera)
              ? _WindowsCameraPlaceholder(
                  onRetry: _initializeCamera,
                  hasCamera: cameraService.isInitialized,
                )
              : _CameraNotAvailable(onRetry: _initializeCamera),

          // 2. Top Bar Layer (Gradient Overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.project.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
          ),

          // 3. Bottom Control Layer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusPill(
                        icon: Icons.timer,
                        text: '${widget.project.intervalSeconds}s Interval',
                      ),
                      if (widget.project.totalShots != null) ...[
                        const SizedBox(width: 12),
                        _StatusPill(
                          icon: Icons.photo_library,
                          text: '${widget.project.totalShots} Shots',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startShooting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        l10n.startShooting,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 高端现代化错误状态组件
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '出错了',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ModernButton(
              text: '重试',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// 相机不可用状态组件
class _CameraNotAvailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _CameraNotAvailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_off_rounded,
                size: 40,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '相机不可用',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '请检查相机权限设置',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                _ModernButton(
                  text: '重试',
                  onPressed: onRetry,
                  icon: Icons.refresh_rounded,
                  isPrimary: true,
                ),
                _ModernButton(
                  text: '返回',
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_back_rounded,
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 现代化按钮组件
class _ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  final bool isPrimary;

  const _ModernButton({
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isPrimary
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          elevation: isPrimary ? 0 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(icon, size: 20),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows 平台相机预览占位组件
class _WindowsCameraPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  final bool hasCamera;

  const _WindowsCameraPlaceholder({
    required this.onRetry,
    this.hasCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (hasCamera ? Colors.green : Colors.blue).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasCamera
                    ? Icons.videocam_rounded
                    : Icons.desktop_windows_rounded,
                size: 40,
                color: hasCamera ? Colors.green.shade400 : Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasCamera ? '相机已连接' : '桌面端预览',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasCamera
                  ? 'Windows 端相机功能已就绪\n可以继续操作'
                  : 'Windows 端不支持实时相机预览\n请连接USB相机或使用移动设备',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                if (!hasCamera)
                  _ModernButton(
                    text: '重试',
                    onPressed: onRetry,
                    icon: Icons.refresh_rounded,
                    isPrimary: true,
                  ),
                _ModernButton(
                  text: hasCamera ? '继续' : '跳过预览',
                  onPressed: () {},
                  icon: hasCamera
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_rounded,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
