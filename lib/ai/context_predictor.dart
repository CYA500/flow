import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/battery_service.dart';
import '../services/weather_service.dart';
import '../services/music_service.dart';
import '../services/match_service.dart';

/// Context Predictor aggregates data from all services
/// to create a unified context for AI decision making
class ContextPredictor {
  static final ContextPredictor _instance = ContextPredictor._internal();
  factory ContextPredictor() => _instance;
  ContextPredictor._internal();

  final BatteryService _batteryService = BatteryService();
  final WeatherService _weatherService = WeatherService();
  final MusicService _musicService = MusicService();
  final MatchService _matchService = MatchService();

  Timer? _updateTimer;
  
  final StreamController<Map<String, dynamic>> _contextController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get contextStream => _contextController.stream;

  Map<String, dynamic> _currentContext = {};
  Map<String, dynamic> get currentContext => Map.unmodifiable(_currentContext);

  /// Initialize all services and start periodic updates
  void initialize() {
    _batteryService.initialize();
    _musicService.startPolling();
    _matchService.startPolling();

    // Listen to individual service streams
    _batteryService.batteryStream.listen((info) {
      _updateContext({
        'batteryLevel': info.level,
        'isCharging': info.isCharging,
        'batteryLow': info.isLow,
      });
    });

    _musicService.musicStream.listen((info) {
      _updateContext({
        'hasMedia': info.title.isNotEmpty,
        'isPlaying': info.isPlaying,
        'mediaTitle': info.title,
        'mediaArtist': info.artist,
      });
    });

    _matchService.matchStream.listen((matches) {
      final liveMatch = matches.firstWhere(
        (m) => m.isLive,
        orElse: () => MatchInfo(
          id: '',
          homeTeam: '',
          awayTeam: '',
          homeScore: 0,
          awayScore: 0,
          competition: '',
          minute: 0,
          isLive: false,
          timestamp: DateTime.now(),
        ),
      );

      _updateContext({
        'hasLiveMatch': liveMatch.isLive,
        'matchMinute': liveMatch.minute,
        'matchCompetition': liveMatch.competition,
      });
    });

    // Periodic weather updates
    _updateTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _updateWeatherContext();
    });
    _updateWeatherContext();

    // Periodic full context update
    Timer.periodic(const Duration(seconds: 30), (_) {
      _emitFullContext();
    });
  }

  Future<void> _updateWeatherContext() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (weather != null) {
        _updateContext({
          'temperature': weather.temperature,
          'weatherCondition': weather.condition,
          'humidity': weather.humidity,
          'windSpeed': weather.windSpeed,
          'weatherIcon': weather.iconCode,
        });
      }
    } catch (e) {
      debugPrint('Weather update error: $e');
    }
  }

  void _updateContext(Map<String, dynamic> updates) {
    _currentContext = {..._currentContext, ...updates};
    _contextController.add(Map.unmodifiable(_currentContext));
  }

  void _emitFullContext() {
    _contextController.add(Map.unmodifiable(_currentContext));
  }

  /// Get context snapshot for immediate use
  Future<Map<String, dynamic>> getContextSnapshot() async {
    // Ensure weather is current
    await _updateWeatherContext();
    return Map.unmodifiable(_currentContext);
  }

  /// Dispose all resources
  void dispose() {
    _updateTimer?.cancel();
    _batteryService.dispose();
    _musicService.dispose();
    _matchService.dispose();
    _contextController.close();
  }
}