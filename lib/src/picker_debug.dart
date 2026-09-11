import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Internal logger for the Search Anchor Picker library.
///
/// Use [PickerDebug.enableLogging] to turn on debug logs.
/// Use [PickerDebug.onLog] to redirect logs to your own system (e.g. Crashlytics).
class PickerDebug {
  /// Global switch to enable internal library logging.
  /// Defaults to false.
  static bool enableLogging = false;

  /// Custom log handler.
  /// If provided, all internal logs will be routed here instead of `dart:developer.log`.
  static void Function(String message)? onLog;

  /// Internal: Logs a message if logging is enabled.
  static void log(String message) {
    if (!enableLogging) return;

    if (onLog != null) {
      onLog!(message);
    } else {
      // In debug mode, print to console/devtools.
      // In release mode, 'dev.log' might still work but usually we only want this in debug.
      if (kDebugMode) {
        dev.log(message, name: 'GenericSearchSelector');
      }
    }
  }
}
