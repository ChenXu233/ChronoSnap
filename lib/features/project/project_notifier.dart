import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/project.dart';
import '../../core/model/camera_config.dart';
import '../../core/repository/project_repository.dart';
import '../../core/service/camera_service.dart';
import '../../core/service/scheduling_service.dart';
import '../../core/service/foreground_service.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

// Repository provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

// Camera service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

// Scheduling service provider
final schedulingServiceProvider = Provider<SchedulingService>((ref) {
  return SchedulingService();
});

// Foreground service provider
final foregroundServiceProvider = Provider<ForegroundService>((ref) {
  return ForegroundService();
});

// Project list provider
final projectListProvider = StateNotifierProvider<ProjectListNotifier, AsyncValue<List<Project>>>((ref) {
  return ProjectListNotifier(ref);
});

class ProjectListNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final Ref _ref;

  ProjectListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(projectRepositoryProvider);
      await repository.initialize();
      final projects = await repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createProject({
    required String name,
    required int intervalSeconds,
    int? totalShots,
    int? durationMinutes,
    required CameraConfig cameraConfig,
    required String storagePath,
  }) async {
    try {
      final repository = _ref.read(projectRepositoryProvider);
      await repository.initialize();

      final project = Project(
        id: _uuid.v4(),
        name: name,
        intervalSeconds: intervalSeconds,
        totalShots: totalShots,
        durationMinutes: durationMinutes,
        cameraConfigJson: cameraConfig.toJsonString(),
        storagePath: storagePath,
        createdTime: DateTime.now(),
        status: ProjectStatus.idle,
      );

      await repository.saveProject(project);
      await loadProjects();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final repository = _ref.read(projectRepositoryProvider);
      await repository.initialize();
      await repository.deleteProject(projectId);
      await loadProjects();
    } catch (e) {
      rethrow;
    }
  }
}

// Active project provider
final activeProjectProvider = StateProvider<Project?>((ref) {
  return null;
});

// Shooting state provider
final shootingStateProvider = StateProvider<ShootingState>((ref) {
  return ShootingState();
});

class ShootingState {
  bool isRunning = false;
  int completedShots = 0;
  DateTime? nextShotTime;
  int batteryLevel = 100;
}
