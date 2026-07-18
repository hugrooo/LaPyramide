import 'package:flutter/services.dart';

/// Prevents screenshots during sensitive game phases (card viewing).
/// Uses platform channels to set FLAG_SECURE (Android) and screen recording
/// prevention (iOS).
class ScreenProtection {
  static const _channel = MethodChannel('app.lapyramide/screen_protection');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // Platform not supported or method not available - silent fail
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
  }
}
