import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/shot_log.dart';
import '../../features/project/project_notifier.dart' as notifier;
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

final shotLogServiceProvider = Provider<ShotLogService>((ref) {
  return ShotLogService(ref);
});

class ShotLogService {
  final Ref _ref;

  ShotLogService(this._ref);

  Future<List<ShotLog>> getLogsForProject(String projectId) async {
    final repository = _ref.read(notifier.projectRepositoryProvider);
    await repository.initialize();
    return repository.getShotLogsForProject(projectId);
  }

  Future<void> logShot({
    required String projectId,
    required int shotNumber,
    required bool success,
    String? photoPath,
    String? errorMessage,
    int? batteryLevel,
    double? durationMinutes,
  }) async {
    final repository = _ref.read(notifier.projectRepositoryProvider);
    await repository.initialize();

    final log = ShotLog(
      id: _uuid.v4(),
      projectId: projectId,
      shotNumber: shotNumber,
      timestamp: DateTime.now(),
      success: success,
      photoPath: photoPath,
      errorMessage: errorMessage,
      batteryLevel: batteryLevel,
      durationMinutes: durationMinutes,
    );

    await repository.saveShotLog(log);
  }
}

extension ShotLogCopyWith on ShotLog {
  ShotLog copyWith({
    String? id,
    String? projectId,
    int? shotNumber,
    DateTime? timestamp,
    bool? success,
    String? photoPath,
    String? errorMessage,
    int? batteryLevel,
    double? durationMinutes,
  }) {
    return ShotLog(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      shotNumber: shotNumber ?? this.shotNumber,
      timestamp: timestamp ?? this.timestamp,
      success: success ?? this.success,
      photoPath: photoPath ?? this.photoPath,
      errorMessage: errorMessage ?? this.errorMessage,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
