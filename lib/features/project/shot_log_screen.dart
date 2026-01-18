import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/model/shot_log.dart';
import '../../core/service/shot_log_service.dart';

final _dateFormat = DateFormat('MM/dd HH:mm:ss');

class ShotLogScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const ShotLogScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ShotLogScreen> createState() => _ShotLogScreenState();
}

class _ShotLogScreenState extends ConsumerState<ShotLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} Logs'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ShotLog>>(
        future: ref
            .read(shotLogServiceProvider)
            .getLogsForProject(widget.projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No shots recorded yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Sort by timestamp descending
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log, index + 1, logs.length);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(ShotLog log, int index, int total) {
    final isError = !log.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red[200]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red[50]
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.red : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shot #${log.shotNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _dateFormat.format(log.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (log.batteryLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getBatteryColor(log.batteryLevel!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${log.batteryLevel}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isError && log.photoPath != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.photoPath!.split('/').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (isError && log.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 16, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }
}
