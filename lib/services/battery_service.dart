import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  final Battery _battery = Battery();
  
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  final StreamController<BatteryInfo> _batteryController = 
      StreamController<BatteryInfo>.broadcast();

  Stream<BatteryInfo> get batteryStream => _batteryController.stream;

  void initialize() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) async {
      final level = await _battery.batteryLevel;
      _batteryController.add(BatteryInfo(
        level: level,
        state: state,
        isLow: level <= 20,
        isCharging: state == BatteryState.charging,
      ));
    });

    // Initial reading
    _getInitialBatteryInfo();
  }

  Future<void> _getInitialBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _batteryController.add(BatteryInfo(
        level: level,
        state: state,
        isLow: level <= 20,
        isCharging: state == BatteryState.charging,
      ));
    } catch (e) {
      _batteryController.addError(e);
    }
  }

  Future<BatteryInfo> getCurrentBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    return BatteryInfo(
      level: level,
      state: state,
      isLow: level <= 20,
      isCharging: state == BatteryState.charging,
    );
  }

  void dispose() {
    _batteryStateSubscription?.cancel();
    _batteryController.close();
  }
}

class BatteryInfo {
  final int level;
  final BatteryState state;
  final bool isLow;
  final bool isCharging;

  BatteryInfo({
    required this.level,
    required this.state,
    required this.isLow,
    required this.isCharging,
  });

  Map<String, dynamic> toMap() => {
    'level': level,
    'state': state.toString(),
    'isLow': isLow,
    'isCharging': isCharging,
  };
}