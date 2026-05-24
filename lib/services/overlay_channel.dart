import 'dart:convert';
import 'package:flutter/services.dart';

class OverlayChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.nowbar/overlay');

  static Future<dynamic> _invokeMethod(String method, [dynamic arguments]) async {
    try {
      final result = await _channel.invokeMethod(method, arguments);
      return result;
    } on PlatformException catch (e) {
      throw OverlayException('${e.code}: ${e.message}');
    } catch (e) {
      throw OverlayException('Unexpected error: $e');
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _invokeMethod('checkOverlayPermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request overlay permission from user
  static Future<void> requestOverlayPermission() async {
    await _invokeMethod('requestOverlayPermission');
  }

  /// Start the NowBar foreground service
  static Future<void> startNowBarService() async {
    await _invokeMethod('startNowBarService');
  }

  /// Stop the NowBar foreground service
  static Future<void> stopNowBarService() async {
    await _invokeMethod('stopNowBarService');
  }

  /// Check if NowBar service is running
  static Future<bool> isNowBarRunning() async {
    try {
      final result = await _invokeMethod('isNowBarRunning');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Send media control command
  static Future<void> sendMediaCommand(String action) async {
    await _invokeMethod('sendMediaCommand', {'action': action});
  }

  /// Get active media session information
  static Future<Map<String, dynamic>> getActiveMediaSession() async {
    try {
      final result = await _invokeMethod('getActiveMediaSession');
      if (result != null && result is String && result.isNotEmpty) {
        return jsonDecode(result) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Request overlay context data
  Future<void> requestOverlayContext() async {
    await _invokeMethod('getOverlayContext');
  }

  /// Set method call handler from native
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }
}

class OverlayException implements Exception {
  final String message;
  OverlayException(this.message);

  @override
  String toString() => 'OverlayException: $message';
}