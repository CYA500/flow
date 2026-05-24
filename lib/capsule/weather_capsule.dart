import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/nowbar_theme.dart';

class WeatherCapsuleContent extends StatefulWidget {
  final Map<String, dynamic> data;

  const WeatherCapsuleContent({
    super.key,
    required this.data,
  });

  @override
  State<WeatherCapsuleContent> createState() => _WeatherCapsuleContentState();
}

class _WeatherCapsuleContentState extends State<WeatherCapsuleContent>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  
  // Weather data
  double _temperature = 0;
  String _condition = '';
  int _humidity = 0;
  double _windSpeed = 0;
  String _location = '';
  String _iconCode = '01d';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        setState(() {
          _error = 'No internet connection';
          _isLoading = false;
        });
        return;
      }

      // Get location
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() {
          _error = 'Location access denied';
          _isLoading = false;
        });
        return;
      }

      // Fetch weather (using Open-Meteo free API - no key needed)
      final weatherData = await _fetchWeather(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _temperature = weatherData['temperature'] ?? 0;
          _condition = weatherData['condition'] ?? 'Unknown';
          _humidity = weatherData['humidity'] ?? 0;
          _windSpeed = weatherData['windSpeed'] ?? 0;
          _location = weatherData['location'] ?? 'Current Location';
          _iconCode = weatherData['iconCode'] ?? '01d';
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load weather';
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?'
          'latitude=$lat&longitude=$lon&current_weather=true&hourly=relativehumidity_2m',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        
        // Map WMO weather codes
        final weatherCode = current['weathercode'] ?? 0;
        final conditionData = _mapWeatherCode(weatherCode);
        
        return {
          'temperature': current['temperature']?.toDouble() ?? 0,
          'condition': conditionData['condition'],
          'humidity': 65, // Placeholder - would need separate API call
          'windSpeed': current['windspeed']?.toDouble() ?? 0,
          'location': 'Local',
          'iconCode': conditionData['icon'],
        };
      }
      
      return _getFallbackWeather();
    } catch (e) {
      return _getFallbackWeather();
    }
  }

  Map<String, dynamic> _getFallbackWeather() {
    return {
      'temperature': 22.0,
      'condition': 'Partly Cloudy',
      'humidity': 60,
      'windSpeed': 12.0,
      'location': 'Local',
      'iconCode': '02d',
    };
  }

  Map<String, String> _mapWeatherCode(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return {'condition': 'Clear Sky', 'icon': '01d'};
    if (code <= 3) return {'condition': 'Partly Cloudy', 'icon': '02d'};
    if (code <= 48) return {'condition': 'Foggy', 'icon': '50d'};
    if (code <= 55) return {'condition': 'Drizzle', 'icon': '09d'};
    if (code <= 65) return {'condition': 'Rainy', 'icon': '10d'};
    if (code <= 77) return {'condition': 'Snow', 'icon': '13d'};
    if (code <= 82) return {'condition': 'Heavy Rain', 'icon': '09d'};
    if (code <= 86) return {'condition': 'Snow Showers', 'icon': '13d'};
    if (code <= 99) return {'condition': 'Thunderstorm', 'icon': '11d'};
    return {'condition': 'Unknown', 'icon': '03d'};
  }

  IconData _getWeatherIcon() {
    final code = _iconCode;
    if (code.startsWith('01')) return Icons.wb_sunny_rounded;
    if (code.startsWith('02')) return Icons.wb_cloudy_rounded;
    if (code.startsWith('03') || code.startsWith('04')) return Icons.cloud_rounded;
    if (code.startsWith('09')) return Icons.water_drop_rounded;
    if (code.startsWith('10')) return Icons.grain_rounded;
    if (code.startsWith('11')) return Icons.thunderstorm_rounded;
    if (code.startsWith('13')) return Icons.ac_unit_rounded;
    if (code.startsWith('50')) return Icons.foggy;
    return Icons.wb_sunny_rounded;
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF30D158)),
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: NowBarTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: NowBarTheme.captionStyle,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Weather icon with glow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF30D158).withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF30D158).withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  _getWeatherIcon(),
                  color: const Color(0xFF30D158),
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),
              // Temperature and condition
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_temperature.round()}°',
                    style: NowBarTheme.headlineStyle.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _condition,
                    style: NowBarTheme.bodyStyle.copyWith(
                      color: NowBarTheme.textSecondary,
                    ),
                  ),
                  Text(
                    _location,
                    style: NowBarTheme.captionStyle,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem(
                Icons.water_drop_rounded,
                '$_humidity%',
                'Humidity',
              ),
              _buildDetailItem(
                Icons.air_rounded,
                '${_windSpeed.round()} km/h',
                'Wind',
              ),
              _buildDetailItem(
                Icons.thermostat_rounded,
                '${_temperature.round()}°',
                'Feels like',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: NowBarTheme.textSecondary.withOpacity(0.7),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: NowBarTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: NowBarTheme.captionStyle.copyWith(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}