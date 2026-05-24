import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/nowbar_theme.dart';

class MatchCapsuleContent extends StatefulWidget {
  final Map<String, dynamic> data;

  const MatchCapsuleContent({
    super.key,
    required this.data,
  });

  @override
  State<MatchCapsuleContent> createState() => _MatchCapsuleContentState();
}

class MatchInfo {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String competition;
  final int minute;
  final bool isLive;
  final String homeTeamLogo;
  final String awayTeamLogo;

  MatchInfo({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.competition,
    required this.minute,
    required this.isLive,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
  });
}

class _MatchCapsuleContentState extends State<MatchCapsuleContent>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  MatchInfo? _match;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        // Use demo data
        _useDemoData();
        return;
      }

      // Try to fetch live scores
      final matchData = await _fetchLiveScores();
      
      if (mounted) {
        if (matchData != null) {
          setState(() {
            _match = matchData;
            _isLoading = false;
          });
        } else {
          _useDemoData();
        }
      }
    } catch (e) {
      _useDemoData();
    }
  }

  Future<MatchInfo?> _fetchLiveScores() async {
    try {
      // Using football-data.org free tier or fallback to demo
      // This is a placeholder - in production you'd use a proper API
      final response = await http.get(
        Uri.parse('https://api.football-data.org/v4/matches'),
        headers: {'X-Auth-Token': 'YOUR_API_KEY'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = data['matches'] as List?;
        
        if (matches != null && matches.isNotEmpty) {
          final match = matches.first;
          return MatchInfo(
            homeTeam: match['homeTeam']['name'] ?? 'Home',
            awayTeam: match['awayTeam']['name'] ?? 'Away',
            homeScore: match['score']['fullTime']['home'] ?? 0,
            awayScore: match['score']['fullTime']['away'] ?? 0,
            competition: match['competition']['name'] ?? 'League',
            minute: match['minute'] ?? 0,
            isLive: match['status'] == 'IN_PLAY',
            homeTeamLogo: match['homeTeam']['crest'] ?? '',
            awayTeamLogo: match['awayTeam']['crest'] ?? '',
          );
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _useDemoData() {
    // Demo match data for display
    final demoMatches = [
      MatchInfo(
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        homeScore: 2,
        awayScore: 1,
        competition: 'La Liga',
        minute: 67,
        isLive: true,
        homeTeamLogo: '',
        awayTeamLogo: '',
      ),
      MatchInfo(
        homeTeam: 'Al-Hilal',
        awayTeam: 'Al-Nassr',
        homeScore: 1,
        awayScore: 1,
        competition: 'SPL',
        minute: 45,
        isLive: true,
        homeTeamLogo: '',
        awayTeamLogo: '',
      ),
    ];

    if (mounted) {
      setState(() {
        _match = demoMatches[math.Random().nextInt(demoMatches.length)];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF375F)),
          ),
        ),
      );
    }

    if (_error != null || _match == null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_soccer_rounded,
                color: NowBarTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No live matches',
                style: NowBarTheme.captionStyle,
              ),
            ],
          ),
        ),
      );
    }

    final match = _match!;

    return Column(
      children: [
        // Competition name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (match.isLive)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF375F).withOpacity(
                        0.5 + (_pulseController.value * 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF375F).withOpacity(
                            0.3 * _pulseController.value,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            Text(
              match.competition.toUpperCase(),
              style: NowBarTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            if (match.isLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF375F).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE',
                  style: NowBarTheme.captionStyle.copyWith(
                    color: const Color(0xFFFF375F),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Teams and score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home team
            Expanded(
              child: Column(
                children: [
                  _buildTeamLogo(match.homeTeam),
                  const SizedBox(height: 8),
                  Text(
                    match.homeTeam,
                    style: NowBarTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF375F).withOpacity(0.2),
                    const Color(0xFFFF9F0A).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${match.homeScore} - ${match.awayScore}',
                    style: NowBarTheme.headlineStyle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (match.isLive)
                    Text(
                      "${match.minute}'",
                      style: NowBarTheme.captionStyle.copyWith(
                        color: const Color(0xFFFF375F),
                      ),
                    ),
                ],
              ),
            ),
            // Away team
            Expanded(
              child: Column(
                children: [
                  _buildTeamLogo(match.awayTeam),
                  const SizedBox(height: 8),
                  Text(
                    match.awayTeam,
                    style: NowBarTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Match time bar
        if (match.isLive)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: match.minute / 90,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF375F)),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamLogo(String teamName) {
    // Generate a colored circle with first letter as placeholder
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFF30D158),
      const Color(0xFFFF9F0A),
      const Color(0xFFFF375F),
      const Color(0xFFBF5AF2),
      const Color(0xFF64D2FF),
    ];
    
    final colorIndex = teamName.hashCode.abs() % colors.length;
    final color = colors[colorIndex];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}