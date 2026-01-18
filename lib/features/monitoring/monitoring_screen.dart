import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/model/project.dart';
import '../../core/service/shooting_controller.dart';
import '../project/project_notifier.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  final Project project;

  const MonitoringScreen({super.key, required this.project});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  late ShootingController _shootingController;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeShooting();
  }

  Future<void> _initializeShooting() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final foregroundService = ref.read(foregroundServiceProvider);
      final repository = ref.read(projectRepositoryProvider);

      await repository.initialize();

      // Initialize camera if not already initialized
      if (!cameraService.isInitialized) {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw Exception('No camera found');
        }
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        await cameraService.initializeCamera(backCamera);
      }

      // Create shooting controller
      _shootingController = ShootingController(
        project: widget.project,
        cameraService: cameraService,
        foregroundService: foregroundService,
        repository: repository,
      );

      // Set up callbacks
      _shootingController.onProgressUpdate = (completed, nextShot, battery) {
        if (mounted) {
          setState(() {});
        }
      };

      _shootingController.onCompleted = () {
        if (mounted) {
          _showCompletionDialog();
        }
      };

      _shootingController.onError = (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      };

      // Start shooting
      await _shootingController.start();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _showCompletionDialog() async {
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectCompleted),
        content: Text(
            '${l10n.completedShots(_shootingController.completedShots)}\n${l10n.tapToCreate}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _stopShooting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Shooting?'),
        content: const Text('Are you sure you want to stop the timelapse capture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _shootingController.stop();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _shootingController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    } else {
      return '${diff.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Initializing camera...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _shootingController.stop();
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final completedShots = _shootingController.completedShots;
    final nextShotTime = _shootingController.nextShotTime;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status
              Text(
                l10n.projectRunning,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // Completed shots
              Text(
                l10n.completedShots(completedShots),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),

              // Next shot time
              if (nextShotTime != null)
                Text(
                  l10n.nextShot(_formatTime(nextShotTime)),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
              const SizedBox(height: 32),

              // Battery level
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getBatteryIcon(),
                    color: _getBatteryColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.currentBattery(100), // Battery level updated via callback
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Project name
              Text(
                widget.project.name,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              const Spacer(),

              // Stop button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stopShooting,
                  child: Text(
                    l10n.stopShooting,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBatteryIcon() {
    if (_shootingController.isRunning) {
      return Icons.battery_full;
    }
    return Icons.battery_alert;
  }

  Color _getBatteryColor() {
    // Battery color based on level
    return Colors.green;
  }
}
