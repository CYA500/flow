import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  Timer? _pollingTimer;
  final StreamController<List<MatchInfo>> _matchController = 
      StreamController<List<MatchInfo>>.broadcast();

  Stream<List<MatchInfo>> get matchStream => _matchController.stream;

  List<MatchInfo>? _cachedMatches;
  DateTime? _lastFetch;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollMatches(); // Initial poll
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _pollMatches();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMatches() async {
    try {
      // Return cached data if fresh (30 seconds)
      if (_cachedMatches != null && _lastFetch != null) {
        if (DateTime.now().difference(_lastFetch!).inSeconds < 30) {
          _matchController.add(_cachedMatches!);
          return;
        }
      }

      final matches = await getLiveMatches();
      _cachedMatches = matches;
      _lastFetch = DateTime.now();
      _matchController.add(matches);
    } catch (e) {
      // Emit cached data on error
      if (_cachedMatches != null) {
        _matchController.add(_cachedMatches!);
      }
    }
  }

  Future<List<MatchInfo>> getLiveMatches() async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return _cachedMatches ?? _getDemoMatches();
      }

      // Try API-FOOTBALL or similar (requires API key in production)
      // For now, return demo data with some randomization
      return _getDemoMatches();
    } catch (e) {
      return _cachedMatches ?? _getDemoMatches();
    }
  }

  List<MatchInfo> _getDemoMatches() {
    final matches = [
      MatchInfo(
        id: '1',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        homeScore: 2,
        awayScore: 1,
        competition: 'La Liga',
        minute: 67,
        isLive: true,
        timestamp: DateTime.now(),
      ),
      MatchInfo(
        id: '2',
        homeTeam: 'Al-Hilal',
        awayTeam: 'Al-Nassr',
        homeScore: 1,
        awayScore: 1,
        competition: 'SPL',
        minute: 45,
        isLive: true,
        timestamp: DateTime.now(),
      ),
      MatchInfo(
        id: '3',
        homeTeam: 'Manchester City',
        awayTeam: 'Liverpool',
        homeScore: 0,
        awayScore: 0,
        competition: 'Premier League',
        minute: 12,
        isLive: true,
        timestamp: DateTime.now(),
      ),
    ];

    // Randomize scores slightly for demo
    final random = math.Random();
    return matches.map((m) {
      if (m.isLive && random.nextBool()) {
        return m.copyWith(
          minute: m.minute + random.nextInt(3),
        );
      }
      return m;
    }).toList();
  }

  Future<MatchInfo?> getMatchDetails(String matchId) async {
    final matches = await getLiveMatches();
    return matches.firstWhere(
      (m) => m.id == matchId,
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
  }

  void dispose() {
    stopPolling();
    _matchController.close();
  }
}

class MatchInfo {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String competition;
  final int minute;
  final bool isLive;
  final DateTime timestamp;

  MatchInfo({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.competition,
    required this.minute,
    required this.isLive,
    required this.timestamp,
  });

  MatchInfo copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
    String? competition,
    int? minute,
    bool? isLive,
    DateTime? timestamp,
  }) {
    return MatchInfo(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      competition: competition ?? this.competition,
      minute: minute ?? this.minute,
      isLive: isLive ?? this.isLive,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'homeTeam': homeTeam,
    'awayTeam': awayTeam,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'competition': competition,
    'minute': minute,
    'isLive': isLive,
  };
}