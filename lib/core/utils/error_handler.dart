import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configuración global para manejo de errores en la aplicación
class ErrorHandler {
  /// Configurar el manejo de errores de Flutter
  static void setupErrorHandling() {
    // Capturar errores de Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        // En producción, registrar el error pero no mostrar UI
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack Trace: ${details.stack}');
      }
    };

    // Capturar errores de zona (async/await)
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Platform Error: $error');
        debugPrint('Stack Trace: $stack');
      }
      return true; // Indicar que el error fue manejado
    };
  }

  /// Widget para mostrar errores de manera segura
  static Widget buildErrorWidget(Object error, StackTrace? stackTrace) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (kDebugMode && stackTrace != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Stack Trace (Debug):',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stackTrace.toString(),
              style: const TextStyle(color: Colors.red, fontSize: 8),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
