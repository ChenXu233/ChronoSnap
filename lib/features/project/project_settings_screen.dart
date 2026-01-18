import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/model/camera_config.dart';
import '../../core/model/project.dart';
import '../../core/service/export_service.dart';
import 'project_notifier.dart';
import '../camera/camera_preview_screen.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

// Weekday constants
const _kWeekdays = [
  {'id': 1, 'label': 'Mon', 'full': 'Monday'},
  {'id': 2, 'label': 'Tue', 'full': 'Tuesday'},
  {'id': 3, 'label': 'Wed', 'full': 'Wednesday'},
  {'id': 4, 'label': 'Thu', 'full': 'Thursday'},
  {'id': 5, 'label': 'Fri', 'full': 'Friday'},
  {'id': 6, 'label': 'Sat', 'full': 'Saturday'},
  {'id': 7, 'label': 'Sun', 'full': 'Sunday'},
];

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  final Project? project;

  const ProjectSettingsScreen({super.key, this.project});

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _intervalController;
  late TextEditingController _totalShotsController;
  late CameraConfig _cameraConfig;

  // Schedule settings
  bool _enableSchedule = false;
  int _startHour = 8;
  int _endHour = 18;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // 默认全选

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _intervalController = TextEditingController(
      text: widget.project?.intervalSeconds.toString() ?? '10',
    );
    _totalShotsController = TextEditingController(
      text: widget.project?.totalShots?.toString() ?? '',
    );
    _cameraConfig = widget.project != null
        ? CameraConfig.fromJsonString(widget.project!.cameraConfigJson)
        : const CameraConfig();

    // Load schedule settings from project
    if (widget.project != null) {
      _enableSchedule = widget.project!.enableSchedule;
      _startHour = widget.project!.startHour ?? 8;
      _endHour = widget.project!.endHour ?? 18;
      _selectedDays = widget.project!.selectedDays ?? [1, 2, 3, 4, 5, 6, 7];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _totalShotsController.dispose();
    super.dispose();
  }

  /// 导出项目照片
  Future<void> _exportProject() async {
    if (widget.project == null) return;

    final l10n = AppLocalizations.of(context);
    final exportService = ref.read(exportServiceProvider);
    final project = widget.project!;

    // 显示加载进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ExportProgressDialog(),
    );

    try {
      // 检查是否有照片
      final hasPhotos = await exportService.hasPhotos(project.storagePath);
      if (!hasPhotos) {
        if (mounted) {
          Navigator.pop(context); // 关闭进度对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有照片可导出')),
          );
        }
        return;
      }

      // 生成 ZIP
      final zipPath = await exportService.exportProjectToZip(
        projectName: project.name,
        storagePath: project.storagePath,
        onProgress: (current, total) {
          // 可以更新进度
        },
      );

      // 关闭进度对话框
      if (mounted) {
        Navigator.pop(context);
      }

      // 分享 ZIP
      await exportService.shareZip(zipPath);

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ];

    final statuses = await permissions.request();

    if (!mounted) return;

    final allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
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

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_enableSchedule && !_isScheduleValid) return;

    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final interval = int.tryParse(_intervalController.text) ?? 10;
    final totalShots = int.tryParse(_totalShotsController.text);

    // Check permissions first
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await _requestPermissions();
      return;
    }

    try {
      Project savedProject;

      if (widget.project != null) {
        // 更新现有项目
        final updatedProject = Project(
          id: widget.project!.id,
          name: name,
          intervalSeconds: interval,
          totalShots: totalShots,
          durationMinutes: null,
          cameraConfigJson: _cameraConfig.toJsonString(),
          storagePath: widget.project!.storagePath,
          createdTime: widget.project!.createdTime,
          status: widget.project!.status,
          completedShots: widget.project!.completedShots,
          lastShotTime: widget.project!.lastShotTime,
          enableSchedule: _enableSchedule,
          startHour: _enableSchedule ? _startHour : null,
          endHour: _enableSchedule ? _endHour : null,
          selectedDays: _enableSchedule ? List<int>.from(_selectedDays) : null,
        );

        final repository = ref.read(projectRepositoryProvider);
        await repository.initialize();
        await repository.saveProject(updatedProject);
        savedProject = updatedProject;
      } else {
        final newProject = Project(
          id: _uuid.v4(),
          name: name,
          intervalSeconds: interval,
          totalShots: totalShots,
          durationMinutes: null,
          cameraConfigJson: _cameraConfig.toJsonString(),
          storagePath: 'ChronoSnap/$name',
          createdTime: DateTime.now(),
          status: ProjectStatus.idle,
          enableSchedule: _enableSchedule,
          startHour: _enableSchedule ? _startHour : null,
          endHour: _enableSchedule ? _endHour : null,
          selectedDays: _enableSchedule ? List<int>.from(_selectedDays) : null,
        );

        await ref
            .read(projectListProvider.notifier)
            .createProject(
              name: name,
              intervalSeconds: interval,
              totalShots: totalShots,
              cameraConfig: _cameraConfig,
              storagePath: 'ChronoSnap/$name',
              enableSchedule: _enableSchedule,
              startHour: _startHour,
              endHour: _endHour,
              selectedDays: List<int>.from(_selectedDays),
            );

        final repository = ref.read(projectRepositoryProvider);
        await repository.initialize();
        savedProject = (await repository.getProject(newProject.id))!;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CameraPreviewScreen(project: savedProject),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;
    final isEditing = widget.project != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Settings' : l10n.createProject),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _exportProject,
              tooltip: 'Export Photos',
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (!isEditing) ...[
                  _SectionHeader(title: 'Basic Info', icon: Icons.info_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.projectName,
                    hint: l10n.projectNameHint,
                    icon: Icons.folder_open,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Name required' : null,
                  ),
                  const SizedBox(height: 32),
                ],
                _SectionHeader(title: 'Capture Settings', icon: Icons.timer),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _intervalController,
                        label: l10n.shootingInterval,
                        suffix: 'sec',
                        icon: Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final val = int.tryParse(v ?? '');
                          if (val == null || val < 1) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _totalShotsController,
                        label: l10n.totalShots,
                        hint: 'Optional',
                        icon: Icons.camera_alt_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Camera Config',
                  icon: Icons.photo_camera,
                ),
                const SizedBox(height: 16),
                _buildCameraToggles(),
                const SizedBox(height: 40),
                _buildScheduleSection(),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _saveAndContinue,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      isEditing ? 'Save Changes' : l10n.startShooting,
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF64748B), size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Auto White Balance',
            subtitle: 'Automatically adjust color balance',
            value: _cameraConfig.autoWhiteBalance,
            onChanged: (v) {
              setState(() {
                _cameraConfig = _cameraConfig.copyWith(autoWhiteBalance: v);
              });
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSwitchTile(
            title: 'Lock Focus',
            subtitle: 'Keep focus fixed during shooting',
            value: _cameraConfig.lockFocus,
            onChanged: (v) {
              setState(() {
                _cameraConfig = _cameraConfig.copyWith(lockFocus: v);
              });
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSwitchTile(
            title: 'Lock Exposure',
            subtitle: 'Keep exposure fixed during shooting',
            value: _cameraConfig.lockExposure,
            onChanged: (v) {
              setState(() {
                _cameraConfig = _cameraConfig.copyWith(lockExposure: v);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Schedule', icon: Icons.schedule),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'Enable Schedule',
                subtitle: 'Only shoot during specified hours',
                value: _enableSchedule,
                onChanged: (v) => setState(() => _enableSchedule = v),
              ),
              if (_enableSchedule) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTimeRangeSelector(),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildDaySelector(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        if (_enableSchedule && !_isScheduleValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'End hour must be after start hour',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  bool get _isScheduleValid {
    if (!_enableSchedule) return true;
    return _startHour < _endHour;
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shooting Hours',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHourPicker(
                  value: _startHour,
                  onChanged: (v) => setState(() => _startHour = v),
                  label: 'Start',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHourPicker(
                  value: _endHour,
                  onChanged: (v) => setState(() => _endHour = v),
                  label: 'End',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourPicker({
    required int value,
    required ValueChanged<int> onChanged,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: InkWell(
            onTap: () => _showHourPicker(context, value, onChanged),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                _formatHour(value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showHourPicker(
    BuildContext context,
    int currentValue,
    ValueChanged<int> onChanged,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Text(
                      'Select Hour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    final hour = index;
                    final isSelected = hour == currentValue;
                    return InkWell(
                      onTap: () {
                        onChanged(hour);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _formatHour(hour),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Days',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kWeekdays.map((day) {
                final isSelected = _selectedDays.contains(day['id'] as int);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(day['label'] as String),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    checkmarkColor: Colors.white,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day['id'] as int);
                        } else {
                          _selectedDays.remove(day['id'] as int);
                        }
                        // 确保至少选中一天
                        if (_selectedDays.isEmpty) {
                          _selectedDays.add(1);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2563EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

/// 导出进度对话框
class _ExportProgressDialog extends StatefulWidget {
  const _ExportProgressDialog();

  @override
  State<_ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<_ExportProgressDialog> {
  int _current = 0;
  int _total = 100;
  String _status = '正在打包照片...';

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    // 模拟初始延迟
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _status = '正在压缩文件...');
    }
  }

  void updateProgress(int current, int total) {
    if (mounted) {
      setState(() {
        _current = current;
        _total = total;
        _status = '正在压缩 (${((current / total) * 100).round()}%)...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _current / _total : 0.0;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress as double?,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _status,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_current / $_total 张照片',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}


