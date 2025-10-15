import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_message.dart';

/// Servicio para manejar operaciones de chat
class ChatService {
  // Usa la IP local de tu PC accesible desde el emulador/dispositivo
  // Ejemplo para emulador Android: 10.0.2.2
  static const String _baseUrl =
      'https://jeanett-uncolorable-pickily.ngrok-free.dev/api';

  final Dio _dio = Dio();
  final AuthService _auth = AuthService();

  ChatService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// Enviar mensaje al chat
  Future<ChatMessage> sendMessage({
    required String message,
    required String model,
    List<ChatMessage>? conversationHistory,
    String? conversationId,
  }) async {
    try {
      AppLogger.chat('📤 Enviando mensaje: $message', tag: 'CHAT_SERVICE');

      final payload = {
        'content': message,
        'model': model,
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
        model: model,
      );

      AppLogger.chat('📥 Respuesta recibida del backend', tag: 'CHAT_SERVICE');
      return assistant;
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
        '/chat',
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
      final chat = Chat(
        id:
            map['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? 'Nueva conversación',
        createdAt:
            DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        model: map['model']?.toString(),
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
        '/chat/$chatId',
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

  /// Obtener modelos disponibles
  List<String> getAvailableModels() {
    return ['ollama', 'gemini', 'openai', 'deepseek'];
  }

  /// Generar respuesta mock para pruebas
  String _generateMockResponse(String userMessage) {
    final responses = [
      '¡Hola! Soy tu asistente de IA. ¿En qué puedo ayudarte?',
      'Entiendo tu pregunta sobre "$userMessage". Déjame explicarte...',
      'Esa es una excelente pregunta. Basándome en mi conocimiento...',
      'Para responder a tu consulta, necesito considerar varios aspectos...',
      'Gracias por tu pregunta. Te puedo ayudar con información sobre "$userMessage".',
    ];

    return responses[DateTime.now().millisecond % responses.length];
  }
}
