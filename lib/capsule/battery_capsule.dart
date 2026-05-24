import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../theme/nowbar_theme.dart';

class BatteryCapsuleContent extends StatefulWidget {
  final Map<String, dynamic> data;

  const BatteryCapsuleContent({
    super.key,
    required this.data,
  });

  @override
  State<BatteryCapsuleContent> createState() => _BatteryCapsuleContentState();
}

class _BatteryCapsuleContentState extends State<BatteryCapsuleContent>
    with SingleTickerProviderStateMixin {
  final Battery _battery = Battery();
  BatteryState _batteryState = BatteryState.unknown;
  int _batteryLevel = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initBattery();
  }

  Future<void> _initBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    
    if (mounted) {
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
      _animationController.animateTo(
        level / 100,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
      );
    }

    // Listen for changes
    _battery.onBatteryStateChanged.listen((state) async {
      final newLevel = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryState = state;
          _batteryLevel = newLevel;
        });
        _animationController.animateTo(
          newLevel / 100,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBatteryColor() {
    if (_batteryLevel <= 20) return const Color(0xFFFF375F);
    if (_batteryLevel <= 50) return const Color(0xFFFF9F0A);
    return const Color(0xFF30D158);
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.bolt_rounded;
    }
    if (_batteryLevel >= 90) return Icons.battery_full_rounded;
    if (_batteryLevel >= 60) return Icons.battery_5_bar_rounded;
    if (_batteryLevel >= 40) return Icons.battery_4_bar_rounded;
    if (_batteryLevel >= 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final batteryColor = _getBatteryColor();
    final isCharging = _batteryState == BatteryState.charging;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Battery icon with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: batteryColor.withOpacity(0.1),
                        border: Border.all(
                          color: batteryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Progress ring
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _animationController.value,
                        strokeWidth: 4,
                        backgroundColor: batteryColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                      ),
                    ),
                    // Icon
                    Icon(
                      _getBatteryIcon(),
                      color: batteryColor,
                      size: 32,
                    ),
                    // Charging indicator
                    if (isCharging)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F0A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9F0A).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 24),
            // Battery info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_batteryLevel%',
                  style: NowBarTheme.headlineStyle.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: batteryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCharging ? 'Charging' : 'Discharging',
                  style: NowBarTheme.bodyStyle.copyWith(
                    color: NowBarTheme.textSecondary,
                  ),
                ),
                if (isCharging)
                  Text(
                    'Fast Charge',
                    style: NowBarTheme.captionStyle.copyWith(
                      color: const Color(0xFFFF9F0A),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Battery bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _animationController.value,
                minHeight: 8,
                backgroundColor: batteryColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Status text
        Text(
          _batteryLevel <= 20
              ? 'Low battery - Connect charger'
              : isCharging
                  ? 'Charging - ${_getEstimatedTime()}'
                  : 'Battery OK',
          style: NowBarTheme.captionStyle.copyWith(
            color: _batteryLevel <= 20
                ? const Color(0xFFFF375F)
                : NowBarTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getEstimatedTime() {
    // Simple estimation
    final remaining = 100 - _batteryLevel;
    if (_batteryLevel > 80) return '20 min to full';
    if (_batteryLevel > 50) return '${remaining * 1.5 ~/ 10} min to full';
    return '${remaining * 2 ~/ 10} min to full';
  }
}