import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/model/project.dart';
import 'project_notifier.dart';
import 'project_settings_screen.dart';

final projectSearchProvider = StateProvider<String>((ref) => '');

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final searchQuery = ref.watch(projectSearchProvider);
    final l10n = AppLocalizations.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projectList),
        actions: [
          _SearchField(isWide: isWideScreen),
          const SizedBox(width: 16),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
        data: (originalList) {
          final projectList = originalList.where((p) {
            return p.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          if (projectList.isEmpty) {
            if (searchQuery.isNotEmpty) {
              return Center(
                child: Text('No projects found matching "$searchQuery"'),
              );
            }
            return _EmptyState(l10n: l10n);
          }

          if (isWideScreen) {
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.5,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: projectList.length,
              itemBuilder: (context, index) {
                final project = projectList[index];
                return _ProjectCard(project: project);
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: projectList.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final project = projectList[index];
              return _ProjectCard(project: project);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProjectSettingsScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.createProject, // Assuming this key exists, based on tapToCreate context
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noProjects,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToCreate,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  final bool isWide;
  const _SearchField({required this.isWide});

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isWide && !_isExpanded) {
      return IconButton(
        icon: const Icon(Icons.search, color: Color(0xFF64748B)),
        onPressed: () {
          setState(() {
            _isExpanded = true;
          });
        },
      );
    }

    return Container(
      width: widget.isWide ? 300 : 200,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _controller,
        autofocus: !widget.isWide,
        onChanged: (value) =>
            ref.read(projectSearchProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: widget.isWide
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _isExpanded = false;
                      _controller.clear();
                      ref.read(projectSearchProvider.notifier).state = '';
                    });
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Calculate progress if totalShots is defined
    double? progress;
    if (project.totalShots != null && project.totalShots! > 0) {
      progress = project.completedShots / project.totalShots!;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectSettingsScreen(project: project),
            ),
          );
        },
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteProject),
              content: Text(l10n.confirmDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          );
          if (confirm == true) {
            ref.read(projectListProvider.notifier).deleteProject(project.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(project.createdTime)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: project.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${project.intervalSeconds}s',
                  ),
                  const SizedBox(width: 16),
                  _InfoChip(
                    icon: Icons.camera_alt_outlined,
                    label: '${project.completedShots}',
                  ),
                  if (project.totalShots != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '/ ${project.totalShots}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9), // Slate-100
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? const Color(0xFF10B981)
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MM/dd HH:mm').format(date);
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case ProjectStatus.running:
        text = l10n.projectRunning;
        color = const Color(0xFF10B981); // Emerald-500
        bgColor = const Color(0xFFECFDF5); // Emerald-50
        break;
      case ProjectStatus.paused:
        text = 'Paused';
        color = const Color(0xFFF59E0B); // Amber-500
        bgColor = const Color(0xFFFFFBEB); // Amber-50
        break;
      case ProjectStatus.completed:
        text = l10n.projectCompleted;
        color = const Color(0xFF3B82F6); // Blue-500
        bgColor = const Color(0xFFEFF6FF); // Blue-50
        break;
      case ProjectStatus.idle:
      default:
        text = l10n.projectIdle;
        color = const Color(0xFF64748B); // Slate-500
        bgColor = const Color(0xFFF1F5F9); // Slate-100
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
