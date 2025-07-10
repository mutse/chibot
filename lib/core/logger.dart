import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static const String _tag = 'ChiBot';
  
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagString = tag ?? _tag;
      final levelString = level.name.toUpperCase();
      
      final logMessage = '[$timestamp] [$levelString] [$tagString] $message';
      
      // Print to console
      print(logMessage);
      
      // Print error and stack trace if provided
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
}

// Extension to make logging easier
extension LoggerExtension on Object {
  void logDebug(String message, {dynamic error, StackTrace? stackTrace}) {
    AppLogger.debug(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logInfo(String message, {dynamic error, StackTrace? stackTrace}) {
    AppLogger.info(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logWarning(String message, {dynamic error, StackTrace? stackTrace}) {
    AppLogger.warning(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    AppLogger.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
}