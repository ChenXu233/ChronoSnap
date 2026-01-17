import 'package:hive/hive.dart';
import '../model/project.dart';
import '../model/shot_log.dart';

class ProjectRepository {
  static const String projectsBoxName = 'projects';
  static const String shotLogsBoxName = 'shot_logs';

  Box<Project>? _projectsBox;
  Box<ShotLog>? _shotLogsBox;

  Future<void> initialize() async {
    _projectsBox ??= await Hive.openBox<Project>(projectsBoxName);
    _shotLogsBox ??= await Hive.openBox<ShotLog>(shotLogsBoxName);
  }

  // Project operations
  Future<List<Project>> getAllProjects() async {
    final box = _projectsBox;
    if (box == null) return [];
    return box.values.toList();
  }

  Future<Project?> getProject(String id) async {
    final box = _projectsBox;
    if (box == null) return null;
    return box.get(id);
  }

  Future<void> saveProject(Project project) async {
    final box = _projectsBox;
    if (box != null) {
      await box.put(project.id, project);
    }
  }

  Future<void> deleteProject(String id) async {
    // Delete associated shot logs
    final logsBox = _shotLogsBox;
    if (logsBox != null) {
      final keysToDelete = <String>[];
      for (final log in logsBox.values) {
        if (log.projectId == id) {
          keysToDelete.add(log.id);
        }
      }
      for (final key in keysToDelete) {
        await logsBox.delete(key);
      }
    }

    final box = _projectsBox;
    if (box != null) {
      await box.delete(id);
    }
  }

  Future<void> updateProjectStatus(
    String id,
    ProjectStatus status, {
    int? completedShots,
    DateTime? lastShotTime,
  }) async {
    final box = _projectsBox;
    if (box == null) return;
    final project = box.get(id);
    if (project != null) {
      final updated = Project(
        id: project.id,
        name: project.name,
        storagePath: project.storagePath,
        intervalSeconds: project.intervalSeconds,
        totalShots: project.totalShots,
        durationMinutes: project.durationMinutes,
        cameraConfigJson: project.cameraConfigJson,
        createdTime: project.createdTime,
        status: status,
        completedShots: completedShots ?? project.completedShots,
        lastShotTime: lastShotTime ?? project.lastShotTime,
      );
      await box.put(id, updated);
    }
  }

  // Shot log operations
  Future<List<ShotLog>> getShotLogsForProject(String projectId) async {
    final box = _shotLogsBox;
    if (box == null) return [];
    return box.values.where((log) => log.projectId == projectId).toList();
  }

  Future<void> saveShotLog(ShotLog log) async {
    final box = _shotLogsBox;
    if (box != null) {
      await box.put(log.id, log);
    }
  }

  // Cleanup
  Future<void> close() async {
    await _projectsBox?.close();
    await _shotLogsBox?.close();
    _projectsBox = null;
    _shotLogsBox = null;
  }
}
