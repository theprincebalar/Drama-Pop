import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.dramapop.app/security');

  static Future<void> enableScreenshotProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('enableSecureMode');
      }
    } catch (e) {
      debugPrint('SecurityService note (enableSecureScreen): $e');
    }
  }

  /// Check if the screen is currently being captured (screen recording or AirPlay)
  static Future<bool> isScreenCaptured() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final res = await _channel.invokeMethod<bool>('isScreenCaptured');
        return res ?? false;
      }
    } catch (e) {
      debugPrint('SecurityService note (isScreenCaptured): $e');
    }
    return false;
  }
}
