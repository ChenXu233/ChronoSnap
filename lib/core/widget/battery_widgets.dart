import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../service/battery_service.dart';

/// Low battery warning dialog with optimization tips
class LowBatteryDialog extends ConsumerStatefulWidget {
  final int batteryLevel;

  const LowBatteryDialog({
    super.key,
    required this.batteryLevel,
  });

  @override
  ConsumerState<LowBatteryDialog> createState() => _LowBatteryDialogState();
}

class _LowBatteryDialogState extends ConsumerState<LowBatteryDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.batteryLevel < 15;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCritical ? Icons.battery_alert : Icons.battery_std,
            color: isCritical ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(isCritical ? 'Battery Critical' : 'Battery Low'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battery is at ${widget.batteryLevel}%. For best results:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildTip(Icons.power, 'Keep device charging during long captures'),
          _buildTip(Icons.screen_lock_portrait, 'Screen may turn off - this is normal'),
          _buildTip(Icons.settings, 'Disable battery optimization for reliable operation'),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              ),
              Text(
                "Don't show again",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_dontShowAgain) {
              ref.read(batteryServiceProvider).resetWarningFlag();
            }
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () async {
            await openAppSettings();
          },
          child: const Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Battery optimization settings screen
class BatteryOptimizationScreen extends StatelessWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Optimization'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'To ensure reliable long-term captures, disable battery optimization for ChronoSnap.',
                    style: TextStyle(color: Color(0xFF856404)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.battery_saver,
            title: 'Why disable optimization?',
            children: [
              _buildListItem('Prevents app from being killed in background'),
              _buildListItem('Ensures timer accuracy for captures'),
              _buildListItem('Keeps notification running'),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            icon: Icons.settings,
            title: 'How to disable:',
            children: [
              _buildListItem('1. Open Settings > Apps'),
              _buildListItem('2. Find ChronoSnap'),
              _buildListItem('3. Tap Battery > Battery optimization'),
              _buildListItem('4. Select "Don\'t optimize"'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  await openAppSettings();
                } catch (_) {}
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Battery Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
