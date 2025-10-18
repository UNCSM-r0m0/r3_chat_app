import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración global para providers y estado de la aplicación
class AppConfig {
  /// Configurar providers para mejor manejo de errores
  static void configureProviders() {
    // Configurar Riverpod para mejor manejo de errores
    if (kDebugMode) {
      // En modo debug, habilitar logging adicional
      debugPrint('🔧 Configuración de providers habilitada para debug');
    }
  }

  /// Configuración de timeout para operaciones de red
  static const Duration networkTimeout = Duration(
    seconds: 120,
  ); // 2 minutos para modelos lentos

  /// Configuración de reintentos para operaciones fallidas
  static const int maxRetries = 3;

  /// Configuración de delay entre reintentos
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Provider para configuración global
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig();
});
