import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  Position? _lastPosition;
  WeatherData? _cachedData;
  DateTime? _lastFetch;

  Future<WeatherData?> getCurrentWeather() async {
    // Return cached data if fresh (5 minutes)
    if (_cachedData != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes < 5) {
        return _cachedData;
      }
    }

    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return _cachedData;
      }

      // Get location
      final position = await _getCurrentPosition();
      if (position == null) {
        return _cachedData;
      }

      _lastPosition = position;

      // Fetch weather from Open-Meteo (free, no API key)
      final data = await _fetchFromOpenMeteo(position.latitude, position.longitude);
      
      _cachedData = data;
      _lastFetch = DateTime.now();
      
      return data;
    } catch (e) {
      return _cachedData;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _lastPosition;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _lastPosition;
      }
      
      if (permission == LocationPermission.deniedForever) return _lastPosition;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return _lastPosition;
    }
  }

  Future<WeatherData> _fetchFromOpenMeteo(double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
        '&timezone=auto',
      ),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final current = data['current'];
      
      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        feelsLike: (current['apparent_temperature'] as num).toDouble(),
        humidity: current['relative_humidity_2m'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        condition: _mapWeatherCode(current['weather_code'] as int),
        iconCode: _getIconCode(current['weather_code'] as int),
        timestamp: DateTime.now(),
      );
    }

    throw Exception('Failed to fetch weather');
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rainy';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Heavy Rain';
    if (code <= 86) return 'Snow Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _getIconCode(int code) {
    if (code == 0) return '01d';
    if (code <= 3) return '02d';
    if (code <= 48) return '50d';
    if (code <= 55) return '09d';
    if (code <= 65) return '10d';
    if (code <= 77) return '13d';
    if (code <= 82) return '09d';
    if (code <= 86) return '13d';
    if (code <= 99) return '11d';
    return '03d';
  }
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String iconCode;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.iconCode,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'temperature': temperature,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'condition': condition,
    'iconCode': iconCode,
  };
}