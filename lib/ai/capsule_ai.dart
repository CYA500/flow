import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../capsule/capsule_manager.dart';

/// Provider for the Capsule AI
final capsuleAIProvider = Provider<CapsuleAI>((ref) => CapsuleAI());

/// AI-powered capsule ranking system
/// Uses rule-based heuristics to prioritize capsules based on context
/// Designed to be extensible for ML model integration
class CapsuleAI {
  
  /// Rank capsules based on current context
  List<CapsuleData> rankCapsules(
    List<CapsuleData> capsules,
    Map<dynamic, dynamic> context,
  ) {
    if (capsules.isEmpty) return [];
    if (context.isEmpty) return capsules;

    // Calculate priority scores for each capsule
    final scoredCapsules = capsules.map((capsule) {
      final score = _calculatePriorityScore(capsule, context);
      return _ScoredCapsule(capsule, score);
    }).toList();

    // Sort by score descending
    scoredCapsules.sort((a, b) => b.score.compareTo(a.score));

    return scoredCapsules.map((s) => s.capsule).toList();
  }

  /// Calculate priority score for a capsule based on context
  double _calculatePriorityScore(CapsuleData capsule, Map<dynamic, dynamic> context) {
    double score = capsule.priority; // Base priority

    switch (capsule.type) {
      case CapsuleType.battery:
        score += _scoreBatteryCapsule(context);
        break;
      case CapsuleType.weather:
        score += _scoreWeatherCapsule(context);
        break;
      case CapsuleType.music:
        score += _scoreMusicCapsule(context);
        break;
      case CapsuleType.match:
        score += _scoreMatchCapsule(context);
        break;
    }

    return score;
  }

  /// Score battery capsule based on battery state
  double _scoreBatteryCapsule(Map<dynamic, dynamic> context) {
    double score = 0.0;

    final batteryLevel = context['batteryLevel'] as int? ?? 50;
    final isCharging = context['isCharging'] as bool? ?? false;

    // High priority if battery is low
    if (batteryLevel <= 15) {
      score += 0.9; // Critical priority
    } else if (batteryLevel <= 30) {
      score += 0.6; // High priority
    } else if (batteryLevel <= 50) {
      score += 0.3; // Medium priority
    }

    // Moderate priority if charging (user might want to see progress)
    if (isCharging) {
      score += 0.2;
    }

    return score;
  }

  /// Score weather capsule based on conditions
  double _scoreWeatherCapsule(Map<dynamic, dynamic> context) {
    double score = 0.0;

    // Check for extreme weather conditions
    final weatherCondition = context['weatherCondition'] as String? ?? '';
    final temperature = context['temperature'] as double?;

    // High priority for extreme weather
    final extremeConditions = [
      'thunderstorm', 'storm', 'tornado', 'hurricane',
      'extreme', 'heavy rain', 'snow', 'blizzard',
    ];

    if (extremeConditions.any((c) => weatherCondition.toLowerCase().contains(c))) {
      score += 0.8;
    }

    // High priority for very high or very low temperatures
    if (temperature != null) {
      if (temperature >= 40 || temperature <= -10) {
        score += 0.6;
      } else if (temperature >= 35 || temperature <= 0) {
        score += 0.3;
      }
    }

    return score;
  }

  /// Score music capsule based on playback state
  double _scoreMusicCapsule(Map<dynamic, dynamic> context) {
    double score = 0.0;

    final hasMedia = context['hasMedia'] as bool? ?? false;
    final isPlaying = context['isPlaying'] as bool? ?? false;

    if (isPlaying) {
      score += 0.7; // High priority when music is actively playing
    } else if (hasMedia) {
      score += 0.4; // Medium priority when media is loaded but paused
    }

    return score;
  }

  /// Score match capsule based on live status
  double _scoreMatchCapsule(Map<dynamic, dynamic> context) {
    double score = 0.0;

    final hasLiveMatch = context['hasLiveMatch'] as bool? ?? false;
    final matchMinute = context['matchMinute'] as int?;

    if (hasLiveMatch) {
      score += 0.8; // High priority for live matches

      // Even higher priority during critical moments
      if (matchMinute != null) {
        if (matchMinute >= 85) {
          score += 0.2; // End of match - critical
        } else if (matchMinute >= 75) {
          score += 0.1; // Late in match
        }
      }
    }

    return score;
  }

  /// Get explanation for why a capsule was prioritized
  String getPriorityExplanation(CapsuleType type, Map<dynamic, dynamic> context) {
    switch (type) {
      case CapsuleType.battery:
        final level = context['batteryLevel'] as int? ?? 50;
        if (level <= 15) return 'Critical battery level';
        if (level <= 30) return 'Low battery warning';
        if (context['isCharging'] == true) return 'Charging in progress';
        return 'Battery status';

      case CapsuleType.weather:
        final condition = context['weatherCondition'] as String? ?? '';
        if (condition.toLowerCase().contains('storm')) return 'Severe weather alert';
        if (condition.toLowerCase().contains('extreme')) return 'Extreme temperature warning';
        return 'Current weather';

      case CapsuleType.music:
        if (context['isPlaying'] == true) return 'Music playing';
        if (context['hasMedia'] == true) return 'Media session active';
        return 'Music controls';

      case CapsuleType.match:
        if (context['hasLiveMatch'] == true) {
          final minute = context['matchMinute'] as int? ?? 0;
          if (minute >= 85) return 'Match ending soon!';
          return 'Live match in progress';
        }
        return 'Match information';
    }
  }
}

/// Internal class for scoring
class _ScoredCapsule {
  final CapsuleData capsule;
  final double score;

  _ScoredCapsule(this.capsule, this.score);
}