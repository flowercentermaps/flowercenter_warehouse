import 'package:flutter/foundation.dart';

class AppLogger {
  static void i(String message, [String? tag]) =>
      _log('INFO', tag, message);
  static void w(String message, [String? tag]) =>
      _log('WARN', tag, message);
  static void e(String message, [String? tag, Object? error]) {
    _log('ERROR', tag, message);
    if (error != null && kDebugMode) debugPrint('  ↳ $error');
  }

  static void _log(String level, String? tag, String msg) {
    if (!kDebugMode) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('[$level]$prefix $msg');
  }
}
