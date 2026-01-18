import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart';

final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryService();
});

class BatteryService {
  final Battery _battery = Battery();
  bool _lowBatteryWarningShown = false;

  /// Get current battery level
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  /// Get battery state
  Future<BatteryState> getBatteryState() async {
    return await _battery.batteryState;
  }

  /// Check if battery is low and needs warning
  Future<bool> shouldShowLowBatteryWarning() async {
    final level = await getBatteryLevel();
    final state = await getBatteryState();

    // Show warning if battery is below 20% and not charging
    if (level < 20 && state != BatteryState.charging) {
      if (!_lowBatteryWarningShown) {
        _lowBatteryWarningShown = true;
        return true;
      }
    } else if (level >= 20) {
      _lowBatteryWarningShown = false;
    }

    return false;
  }

  /// Reset warning flag
  void resetWarningFlag() {
    _lowBatteryWarningShown = false;
  }

  /// Check if device is on battery power (not charging)
  Future<bool> isOnBatteryPower() async {
    final state = await getBatteryState();
    return state == BatteryState.discharging;
  }

  /// Get battery health status
  String getBatteryHealthMessage(int level) {
    if (level >= 50) {
      return 'Battery level is good';
    } else if (level >= 20) {
      return 'Battery is getting low';
    } else {
      return 'Battery critically low!';
    }
  }
}
