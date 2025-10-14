import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';
import '../models/chat_message.dart';

/// Servicio para manejar operaciones de chat
class ChatService {
  static const String _baseUrl =
      'http://localhost:3000'; // TODO: Cambiar por URL real

  final Dio _dio = Dio();

  ChatService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  /// Enviar mensaje al chat
  Future<ChatMessage> sendMessage({
    required String message,
    required String model,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      AppLogger.chat('📤 Enviando mensaje: $message', tag: 'CHAT_SERVICE');

      // Simular respuesta para pruebas
      await Future.delayed(const Duration(seconds: 2));

      final response = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: _generateMockResponse(message),
        timestamp: DateTime.now(),
        model: model,
      );

      AppLogger.chat('📥 Respuesta recibida', tag: 'CHAT_SERVICE');
      return response;
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

      // Simular datos para pruebas
      await Future.delayed(const Duration(seconds: 1));

      final chats = [
        Chat(
          id: '1',
          title: '¿Cómo funciona Flutter?',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          model: 'gpt-4',
        ),
        Chat(
          id: '2',
          title: 'Explicación de MVVM',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          model: 'claude-3',
        ),
      ];

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

      await Future.delayed(const Duration(milliseconds: 500));

      final chat = Chat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Nueva conversación',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

      await Future.delayed(const Duration(milliseconds: 300));

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
