import 'package:flutter/foundation.dart';

/// Logger personalizado que solo muestra logs en desarrollo
/// En producción, todos los logs se silencian automáticamente
class AppLogger {
  static const String _appName = 'R3Chat';

  /// Log de información (azul)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      _log('INFO', message, tag: tag, color: '\x1B[34m'); // Azul
    }
  }

  /// Log de advertencia (amarillo)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      _log('WARNING', message, tag: tag, color: '\x1B[33m'); // Amarillo
    }
  }

  /// Log de error (rojo)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _log('ERROR', message, tag: tag, color: '\x1B[31m'); // Rojo
      if (error != null) {
        _log('ERROR', 'Exception: $error', tag: tag, color: '\x1B[31m');
      }
      if (stackTrace != null) {
        _log('ERROR', 'StackTrace: $stackTrace', tag: tag, color: '\x1B[31m');
      }
    }
  }

  /// Log de éxito (verde)
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      _log('SUCCESS', message, tag: tag, color: '\x1B[32m'); // Verde
    }
  }

  /// Log de debug (cian)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, color: '\x1B[36m'); // Cian
    }
  }

  /// Log de red/API (magenta)
  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      _log('NETWORK', message, tag: tag, color: '\x1B[35m'); // Magenta
    }
  }

  /// Log de autenticación (púrpura)
  static void auth(String message, {String? tag}) {
    if (kDebugMode) {
      _log('AUTH', message, tag: tag, color: '\x1B[35m'); // Púrpura
    }
  }

  /// Log de chat (verde claro)
  static void chat(String message, {String? tag}) {
    if (kDebugMode) {
      _log('CHAT', message, tag: tag, color: '\x1B[92m'); // Verde claro
    }
  }

  /// Método interno para formatear y mostrar logs
  static void _log(
    String level,
    String message, {
    String? tag,
    required String color,
  }) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag != null ? '[$tag]' : '';
    final resetColor = '\x1B[0m'; // Reset color

    // ignore: avoid_print
    print('$color[$_appName] $timestamp [$level]$tagStr $message$resetColor');
  }

  /// Log de objeto complejo (JSON, Map, etc.)
  static void object(String label, Object obj, {String? tag}) {
    if (kDebugMode) {
      _log(
        'OBJECT',
        '$label: ${obj.toString()}',
        tag: tag,
        color: '\x1B[37m',
      ); // Blanco
    }
  }

  /// Log de performance/timing
  static void performance(String operation, Duration duration, {String? tag}) {
    if (kDebugMode) {
      final ms = duration.inMilliseconds;
      final color = ms > 1000
          ? '\x1B[31m'
          : ms > 500
          ? '\x1B[33m'
          : '\x1B[32m';
      _log('PERF', '$operation took ${ms}ms', tag: tag, color: color);
    }
  }

  /// Separador visual para logs
  static void separator({String? tag}) {
    if (kDebugMode) {
      _log(
        'SEPARATOR',
        '════════════════════════════════════════',
        tag: tag,
        color: '\x1B[90m',
      ); // Gris
    }
  }
}

/// Extension para facilitar el uso del logger
extension LoggerExtension on Object {
  void logInfo(String message, {String? tag}) =>
      AppLogger.info(message, tag: tag);
  void logWarning(String message, {String? tag}) =>
      AppLogger.warning(message, tag: tag);
  void logError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      AppLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  void logSuccess(String message, {String? tag}) =>
      AppLogger.success(message, tag: tag);
  void logDebug(String message, {String? tag}) =>
      AppLogger.debug(message, tag: tag);
  void logNetwork(String message, {String? tag}) =>
      AppLogger.network(message, tag: tag);
  void logAuth(String message, {String? tag}) =>
      AppLogger.auth(message, tag: tag);
  void logChat(String message, {String? tag}) =>
      AppLogger.chat(message, tag: tag);
}
