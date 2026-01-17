import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/project.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/service/camera_service.dart';
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
  CameraDescription? _camera;
  bool _isInitializing = false;
  String? _errorMessage;

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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found';
          _isInitializing = false;
        });
        return;
      }

      // Use back camera if available
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final cameraService = ref.read(cameraServiceProvider);
      await cameraService.initializeCamera(_camera!);

      // Apply camera config
      final config = widget.project.cameraConfigJson;
      // Config application would go here

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

  @override
  void dispose() {
    ref.read(cameraServiceProvider).dispose();
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
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          TextButton(
            onPressed: _startShooting,
            child: Text(l10n.startShooting),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorState(
                        message: _errorMessage!,
                        onRetry: _initializeCamera,
                      )
                    : cameraService.controller != null
                        ? CameraPreview(cameraService.controller!)
                        : _CameraNotAvailable(
                            onRetry: _initializeCamera,
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${l10n.shootingInterval}: ${widget.project.intervalSeconds}s',
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.project.totalShots != null)
                  Text(
                    '${l10n.totalShots}: ${widget.project.totalShots}',
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startShooting,
                    child: Text(l10n.startShooting),
                  ),
                ),
              ],
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
              : theme.colorScheme.surfaceVariant,
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
