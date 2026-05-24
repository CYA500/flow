import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/capsule_ai.dart';

// Enum for capsule types
enum CapsuleType {
  battery,
  weather,
  music,
  match,
}

// Capsule data model
class CapsuleData {
  final CapsuleType type;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final double priority;
  final Map<String, dynamic> data;

  const CapsuleData({
    required this.type,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.priority,
    this.data = const {},
  });

  CapsuleData copyWith({
    CapsuleType? type,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? accentColor,
    double? priority,
    Map<String, dynamic>? data,
  }) {
    return CapsuleData(
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      priority: priority ?? this.priority,
      data: data ?? this.data,
    );
  }
}

// Context provider for AI decisions
final capsuleContextProvider = StateProvider<Map<dynamic, dynamic>>((ref) => {});

// Raw capsules provider
final rawCapsulesProvider = StateNotifierProvider<CapsuleNotifier, List<CapsuleData>>((ref) {
  return CapsuleNotifier(ref);
});

// AI-sorted capsules provider
final sortedCapsulesProvider = Provider<List<CapsuleData>>((ref) {
  final capsules = ref.watch(rawCapsulesProvider);
  final context = ref.watch(capsuleContextProvider);
  final ai = ref.read(capsuleAIProvider);
  
  return ai.rankCapsules(capsules, context);
});

// Capsule notifier
class CapsuleNotifier extends StateNotifier<List<CapsuleData>> {
  final Ref ref;

  CapsuleNotifier(this.ref) : super([]) {
    _initializeCapsules();
  }

  void _initializeCapsules() {
    state = [
      const CapsuleData(
        type: CapsuleType.battery,
        title: 'Battery',
        subtitle: 'Device power',
        icon: Icons.battery_full_rounded,
        accentColor: Color(0xFF0A84FF),
        priority: 0.5,
      ),
      const CapsuleData(
        type: CapsuleType.weather,
        title: 'Weather',
        subtitle: 'Current conditions',
        icon: Icons.wb_sunny_rounded,
        accentColor: Color(0xFF30D158),
        priority: 0.3,
      ),
      const CapsuleData(
        type: CapsuleType.music,
        title: 'Music',
        subtitle: 'Now playing',
        icon: Icons.music_note_rounded,
        accentColor: Color(0xFFFF9F0A),
        priority: 0.4,
      ),
      const CapsuleData(
        type: CapsuleType.match,
        title: 'Live Match',
        subtitle: 'Football',
        icon: Icons.sports_soccer_rounded,
        accentColor: Color(0xFFFF375F),
        priority: 0.6,
      ),
    ];
  }

  void updateCapsuleData(CapsuleType type, Map<String, dynamic> newData) {
    state = [
      for (final capsule in state)
        if (capsule.type == type)
          capsule.copyWith(data: {...capsule.data, ...newData})
        else
          capsule,
    ];
  }

  void updatePriority(CapsuleType type, double newPriority) {
    state = [
      for (final capsule in state)
        if (capsule.type == type)
          capsule.copyWith(priority: newPriority)
        else
          capsule,
    ];
  }

  void setCapsules(List<CapsuleData> capsules) {
    state = capsules;
  }
}