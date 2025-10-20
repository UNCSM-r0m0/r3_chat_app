import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_message.dart';
import '../models/ai_model.dart';

/// Servicio para manejar operaciones de chat
class ChatService {
  final Dio _dio = Dio();
  final AuthService _auth = AuthService();

  ChatService() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;
    _dio.options.headers = AppConfig.defaultHeaders;
  }

  /// Enviar mensaje al chat
  Future<ChatResponse> sendMessage({
    required String message,
    required String model,
    List<ChatMessage>? conversationHistory,
    String? conversationId,
  }) async {
    try {
      AppLogger.chat('📤 Enviando mensaje: $message', tag: 'CHAT_SERVICE');

      // Normalizar modelo: si viene 'ollama' a secas, usar uno soportado por el backend
      final String normalizedModel =
          (model.trim().toLowerCase() == 'ollama')
              ? 'ollama-qwen2.5-coder:7b'
              : model;

      final payload = {
        'content': message,
        'model': normalizedModel,
        if (conversationId != null) 'conversationId': conversationId,
      };

      final token = await _auth.getToken();
      final res = await _dio.post(
        '/chat/message',
        data: payload,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);

      // Backend devuelve { conversationId, message: { id, role, content, createdAt, tokensUsed }, remaining, limit, tier }
      final messageData = data['message'] as Map<String, dynamic>?;
      final assistant = ChatMessage(
        id:
            messageData?['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: messageData?['content']?.toString() ?? 'Sin respuesta',
        timestamp:
            DateTime.tryParse(messageData?['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        model: normalizedModel,
      );

      AppLogger.chat('📥 Respuesta recibida del backend', tag: 'CHAT_SERVICE');
      final remaining = (res.data as Map)['remaining'];
      final limit = (res.data as Map)['limit'];
      final tier = (res.data as Map)['tier']?.toString();
      return ChatResponse(
        message: assistant,
        remaining: (remaining is int)
            ? remaining
            : int.tryParse(remaining?.toString() ?? ''),
        limit: (limit is int) ? limit : int.tryParse(limit?.toString() ?? ''),
        tier: tier,
      );
    } catch (error) {
      AppLogger.error(
        '❌ Error enviando mensaje',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Obtener historial de chats
  Future<List<Chat>> getChatHistory() async {
    try {
      AppLogger.chat('📋 Obteniendo historial de chats', tag: 'CHAT_SERVICE');

      final token = await _auth.getToken();
      final res = await _dio.get(
        '/chat/sessions',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      // El backend devuelve { success: true, data: chats[], message: '...' }
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];

      final chats = list.map<Chat>((item) {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);
        return Chat(
          id: map['id']?.toString() ?? '',
          title: map['title']?.toString() ?? 'Nuevo Chat',
          createdAt:
              DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
          model: map['model']?.toString(),
        );
      }).toList();

      AppLogger.chat(
        '✅ Historial obtenido: ${chats.length} chats',
        tag: 'CHAT_SERVICE',
      );
      return chats;
    } catch (error) {
      AppLogger.error(
        '❌ Error obteniendo historial',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Crear nuevo chat
  Future<Chat> createNewChat() async {
    try {
      AppLogger.chat('🆕 Creando nuevo chat', tag: 'CHAT_SERVICE');
      final token = await _auth.getToken();
      final res = await _dio.post(
        '/chat',
        data: {},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      final map = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);
      final chatMap = (map['data'] ?? map) as Map<String, dynamic>;
      final chat = Chat(
        id: chatMap['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: chatMap['title']?.toString() ?? 'Nueva conversación',
        createdAt: DateTime.tryParse(chatMap['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(chatMap['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        model: chatMap['model']?.toString(),
      );
      AppLogger.chat('✅ Chat creado: ${chat.id}', tag: 'CHAT_SERVICE');
      return chat;
    } catch (error) {
      AppLogger.error(
        '❌ Error creando chat',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Eliminar chat
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.chat('🗑️ Eliminando chat: $chatId', tag: 'CHAT_SERVICE');
      final token = await _auth.getToken();
      await _dio.delete(
        '/chat/sessions/$chatId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      AppLogger.chat('✅ Chat eliminado', tag: 'CHAT_SERVICE');
    } catch (error) {
      AppLogger.error(
        '❌ Error eliminando chat',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Obtener un chat específico con sus mensajes
  Future<Chat> getChat(String chatId) async {
    try {
      AppLogger.chat('↗️ Solicitando chat $chatId', tag: 'CHAT_SERVICE');
      final token = await _auth.getToken();
      final res = await _dio.get(
        '/chat/$chatId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final map = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);

      final data = (map['data'] ?? map['chat']) as Map<String, dynamic>;

      final messagesList = (data['messages'] as List<dynamic>? ?? [])
          .map<ChatMessage>((m) {
            final mm = m is Map<String, dynamic>
                ? m
                : Map<String, dynamic>.from(m);
            final roleStr = (mm['role'] ?? mm['sender'] ?? 'assistant')
                .toString();
            final role = roleStr.toLowerCase() == 'user'
                ? ChatRole.user
                : roleStr.toLowerCase() == 'system'
                ? ChatRole.system
                : ChatRole.assistant;
            return ChatMessage(
              id:
                  (mm['id'] ??
                          mm['messageId'] ??
                          DateTime.now().millisecondsSinceEpoch.toString())
                      .toString(),
              role: role,
              content: (mm['content'] ?? mm['text'] ?? '').toString(),
              timestamp:
                  DateTime.tryParse(
                    (mm['createdAt'] ?? mm['timestamp'] ?? '').toString(),
                  ) ??
                  DateTime.now(),
            );
          })
          .toList();

      final chat = Chat(
        id: data['id']?.toString() ?? chatId,
        title: data['title']?.toString() ?? 'Conversación',
        createdAt:
            DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        model: data['model']?.toString(),
        messages: messagesList,
      );

      AppLogger.chat(
        '✔️ Chat cargado (${messagesList.length} msgs)',
        tag: 'CHAT_SERVICE',
      );
      return chat;
    } catch (error) {
      AppLogger.error(
        '✖ Error obteniendo chat',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Obtener modelos disponibles desde el backend
  Future<List<AIModel>> getAvailableModels() async {
    try {
      AppLogger.chat('🤖 Obteniendo modelos disponibles', tag: 'CHAT_SERVICE');

      final token = await _auth.getToken();
      final res = await _dio.get(
        '/models/public',
        options: Options(headers: AppConfig.defaultHeaders),
      );

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);

      final response = AvailableModelsResponse.fromJson(data);

      AppLogger.chat(
        '✅ Modelos obtenidos: ${response.models.length} modelos disponibles',
        tag: 'CHAT_SERVICE',
      );

      return response.models;
    } catch (error) {
      AppLogger.error(
        '❌ Error obteniendo modelos disponibles',
        tag: 'CHAT_SERVICE',
        error: error,
      );

      // Fallback a modelos hardcodeados en caso de error
      AppLogger.chat('🔄 Usando modelos de fallback', tag: 'CHAT_SERVICE');
      return _getFallbackModels();
    }
  }

  /// Modelos de fallback en caso de error del backend
  List<AIModel> _getFallbackModels() {
    return [
      const AIModel(
        id: 'ollama',
        name: 'Ollama Local',
        provider: 'Local',
        available: true,
        isPremium: false,
        features: ['text-generation', 'local-processing'],
        description: 'Modelo local ejecutándose en tu servidor',
        defaultModel: 'qwen2.5-coder:7b',
      ),
      const AIModel(
        id: 'gemini',
        name: 'Gemini 2.0 Flash',
        provider: 'Google',
        available: true,
        isPremium: true,
        features: ['text-generation', 'multimodal', 'streaming'],
        description: 'Modelo avanzado de Google con capacidades multimodales',
        defaultModel: 'gemini-2.0-flash-exp',
      ),
      const AIModel(
        id: 'openai',
        name: 'GPT-4o Mini',
        provider: 'OpenAI',
        available: true,
        isPremium: true,
        features: ['text-generation', 'streaming', 'chat-completions'],
        description: 'Modelo de OpenAI optimizado para chat y conversaciones',
        defaultModel: 'gpt-4o-mini',
      ),
      const AIModel(
        id: 'deepseek',
        name: 'DeepSeek Chat',
        provider: 'DeepSeek',
        available: true,
        isPremium: true,
        features: ['text-generation', 'cost-effective', 'high-performance'],
        description: 'Modelo de DeepSeek con excelente relación precio-calidad',
        defaultModel: 'deepseek-chat',
      ),
    ];
  }
}

class ChatResponse {
  final ChatMessage message;
  final int? remaining;
  final int? limit;
  final String? tier;

  ChatResponse({required this.message, this.remaining, this.limit, this.tier});
}
