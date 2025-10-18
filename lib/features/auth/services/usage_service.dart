import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';
import 'auth_service.dart';

/// Modelo para las estadísticas de uso del usuario
class UsageStats {
  final int todayMessages;
  final int todayTokens;
  final int totalMessages;
  final int totalTokens;
  final String tier;
  final UsageLimits limits;

  const UsageStats({
    required this.todayMessages,
    required this.todayTokens,
    required this.totalMessages,
    required this.totalTokens,
    required this.tier,
    required this.limits,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      todayMessages: json['todayMessages'] ?? 0,
      todayTokens: json['todayTokens'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      tier: json['tier'] ?? 'FREE',
      limits: UsageLimits.fromJson(json['limits'] ?? {}),
    );
  }
}

/// Modelo para los límites de uso
class UsageLimits {
  final int messagesPerDay;
  final int maxTokensPerMessage;
  final bool canUploadImages;

  const UsageLimits({
    required this.messagesPerDay,
    required this.maxTokensPerMessage,
    required this.canUploadImages,
  });

  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      messagesPerDay: json['messagesPerDay'] ?? 0,
      maxTokensPerMessage: json['maxTokensPerMessage'] ?? 0,
      canUploadImages: json['canUploadImages'] ?? false,
    );
  }
}

/// Servicio para manejar estadísticas de uso
class UsageService {
  static const String _baseUrl =
      'https://jeanett-uncolorable-pickily.ngrok-free.dev/api';

  final Dio _dio = Dio();
  final AuthService _auth = AuthService();

  UsageService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Obtener estadísticas de uso del usuario
  Future<UsageStats> getUsageStats() async {
    try {
      AppLogger.chat('📊 Obteniendo estadísticas de uso', tag: 'USAGE_SERVICE');

      final token = await _auth.getToken();
      final res = await _dio.get(
        '/chat/usage/stats',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);

      final stats = UsageStats.fromJson(data);

      AppLogger.chat(
        '✅ Estadísticas obtenidas: ${stats.todayMessages}/${stats.limits.messagesPerDay} mensajes hoy',
        tag: 'USAGE_SERVICE',
      );

      return stats;
    } catch (error) {
      AppLogger.error(
        '❌ Error obteniendo estadísticas de uso',
        tag: 'USAGE_SERVICE',
        error: error,
      );
      rethrow;
    }
  }
}
