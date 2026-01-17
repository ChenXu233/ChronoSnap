import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/model/camera_config.dart';
import '../../core/model/project.dart';
import '../../core/repository/project_repository.dart';
import 'project_notifier.dart';
import '../camera/camera_preview_screen.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class ProjectSettingsScreen extends ConsumerWidget {
  final Project? project;

  const ProjectSettingsScreen({super.key, this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isEditing = project != null;

    final nameController = TextEditingController(text: project?.name ?? '');
    final intervalController = TextEditingController(
      text: project?.intervalSeconds.toString() ?? '10',
    );
    final totalShotsController = TextEditingController(
      text: project?.totalShots?.toString() ?? '',
    );

    final cameraConfig = StateProvider<CameraConfig>((ref) {
      if (project != null) {
        return CameraConfig.fromJsonString(project!.cameraConfigJson);
      }
      return const CameraConfig();
    });

    Future<void> requestPermissions() async {
      final permissions = [
        Permission.camera,
        Permission.storage,
        Permission.notification,
      ];

      final statuses = await permissions.request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      if (!allGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please grant all permissions in Settings'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
    }

    Future<void> saveAndContinue() async {
      final name = nameController.text.trim();
      final interval = int.tryParse(intervalController.text) ?? 10;
      final totalShots = int.tryParse(totalShotsController.text);
      final config = ref.read(cameraConfig);

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter project name')),
        );
        return;
      }

      // Check permissions first
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        await requestPermissions();
        return;
      }

      try {
        Project savedProject;

        if (isEditing && project != null) {
          savedProject = project!;
        } else {
          final newProject = Project(
            id: _uuid.v4(),
            name: name,
            intervalSeconds: interval,
            totalShots: totalShots,
            durationMinutes: null,
            cameraConfigJson: config.toJsonString(),
            storagePath: 'ChronoSnap/$name',
            createdTime: DateTime.now(),
            status: ProjectStatus.idle,
          );

          await ref.read(projectListProvider.notifier).createProject(
                name: name,
                intervalSeconds: interval,
                totalShots: totalShots,
                cameraConfig: config,
                storagePath: 'ChronoSnap/$name',
              );

          // Fetch the saved project
          final repository = ref.read(projectRepositoryProvider);
          await repository.initialize();
          savedProject = (await repository.getProject(newProject.id))!;
        }

        if (context.mounted) {
          // Navigate to camera preview
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPreviewScreen(project: savedProject),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    Future<void> saveOnly() async {
      final name = nameController.text.trim();
      final interval = int.tryParse(intervalController.text) ?? 10;
      final totalShots = int.tryParse(totalShotsController.text);
      final config = ref.read(cameraConfig);

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter project name')),
        );
        return;
      }

      try {
        if (isEditing && project != null) {
          // Update existing project
          final repository = ref.read(projectRepositoryProvider);
          await repository.initialize();
          await repository.updateProjectStatus(
            project!.id,
            ProjectStatus.idle,
          );
        } else {
          await ref.read(projectListProvider.notifier).createProject(
                name: name,
                intervalSeconds: interval,
                totalShots: totalShots,
                cameraConfig: config,
                storagePath: 'ChronoSnap/$name',
              );
        }

        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : l10n.createProject),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.projectName,
                hintText: l10n.projectNameHint,
              ),
            ),
            const SizedBox(height: 16),

            // Shooting Interval
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.shootingInterval,
                suffixText: 'seconds',
              ),
            ),
            const SizedBox(height: 16),

            // Total Shots
            TextField(
              controller: totalShotsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.totalShots,
                hintText: l10n.totalShotsHint,
              ),
            ),
            const SizedBox(height: 24),

            // Camera Settings
            ExpansionTile(
              title: Text(l10n.cameraSettings),
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final config = ref.watch(cameraConfig);
                    return Column(
                      children: [
                        SwitchListTile(
                          title: Text(l10n.lockFocus),
                          value: config.lockFocus,
                          onChanged: (value) {
                            ref.read(cameraConfig.notifier).state =
                                config.copyWith(lockFocus: value);
                          },
                        ),
                        SwitchListTile(
                          title: Text(l10n.lockExposure),
                          value: config.lockExposure,
                          onChanged: (value) {
                            ref.read(cameraConfig.notifier).state =
                                config.copyWith(lockExposure: value);
                          },
                        ),
                        SwitchListTile(
                          title: Text(l10n.autoWhiteBalance),
                          value: config.autoWhiteBalance,
                          onChanged: (value) {
                            ref.read(cameraConfig.notifier).state =
                                config.copyWith(autoWhiteBalance: value);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!isEditing) ...[
              // Create mode: Save and Start
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveAndContinue,
                  icon: const Icon(Icons.camera_alt),
                  label: Text('${l10n.createProject} & Start'),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Edit mode: Start Shooting
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveAndContinue,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startShooting),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Save Only button (for editing existing projects)
            if (isEditing)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: saveOnly,
                  child: const Text('Save Only'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
