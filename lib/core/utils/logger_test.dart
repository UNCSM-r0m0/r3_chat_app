import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Clase de prueba para verificar que el logger funciona correctamente
class LoggerTest {
  static void runAllTests() {
    if (kDebugMode) {
      print('\n🧪 === PRUEBAS DEL LOGGER ===\n');

      // Test de todos los tipos de log
      AppLogger.info('✅ Test de información', tag: 'TEST');
      AppLogger.success('✅ Test de éxito', tag: 'TEST');
      AppLogger.warning('⚠️ Test de advertencia', tag: 'TEST');
      AppLogger.error('❌ Test de error', tag: 'TEST');
      AppLogger.debug('🔍 Test de debug', tag: 'TEST');
      AppLogger.network('🌐 Test de red', tag: 'TEST');
      AppLogger.auth('🔐 Test de autenticación', tag: 'TEST');
      AppLogger.chat('💬 Test de chat', tag: 'TEST');

      // Test de separador
      AppLogger.separator(tag: 'TEST');

      // Test de performance
      final stopwatch = Stopwatch()..start();
      // Simular operación
      for (int i = 0; i < 1000000; i++) {
        // Operación dummy
      }
      stopwatch.stop();
      AppLogger.performance('Operación dummy', stopwatch.elapsed, tag: 'TEST');

      // Test de objeto
      final testMap = {'nombre': 'R3Chat', 'version': '1.0.0', 'debug': true};
      AppLogger.object('Configuración de app', testMap, tag: 'TEST');

      AppLogger.separator(tag: 'TEST');
      AppLogger.info(
        '🎉 Todas las pruebas del logger completadas',
        tag: 'TEST',
      );
      print('\n🧪 === FIN DE PRUEBAS ===\n');
    }
  }
}
