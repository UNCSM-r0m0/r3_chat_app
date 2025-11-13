import 'dart:async';
import 'dart:convert';
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
      final String normalizedModel = (model.trim().toLowerCase() == 'ollama')
          ? 'ollama-qwen2.5-coder:7b'
          : model;

      final payload = {
        'content': message,
        'model': normalizedModel,
        if (conversationId != null) 'conversationId': conversationId,
      };

      // Modelos locales (LLM Studio) pueden tardar más tiempo (hasta 5 minutos)
      // Modelos cloud suelen ser más rápidos (2 minutos)
      final bool isLocalModel =
          normalizedModel.toLowerCase() == 'openai' ||
          normalizedModel.toLowerCase().startsWith('ollama');
      final Duration timeout = isLocalModel
          ? const Duration(minutes: 5) // 5 minutos para modelos locales
          : const Duration(minutes: 2); // 2 minutos para modelos cloud

      AppLogger.chat(
        '⏱️ Timeout configurado: ${timeout.inMinutes} minutos (modelo: ${isLocalModel ? "local" : "cloud"})',
        tag: 'CHAT_SERVICE',
      );

      final token = await _auth.getToken();
      final res = await _dio.post(
        '/chat/message',
        data: payload,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          receiveTimeout: timeout,
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      AppLogger.chat(
        '📥 Respuesta recibida del backend (status: ${res.statusCode})',
        tag: 'CHAT_SERVICE',
      );

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data);

      AppLogger.chat(
        '📋 Datos parseados: ${data.keys.join(", ")}',
        tag: 'CHAT_SERVICE',
      );

      // Backend devuelve { conversationId, message: { id, role, content, createdAt, tokensUsed }, remaining, limit, tier }
      final messageData = data['message'] as Map<String, dynamic>?;

      if (messageData == null) {
        AppLogger.error(
          '❌ messageData es null. Datos recibidos: ${data.toString()}',
          tag: 'CHAT_SERVICE',
        );
        throw Exception('Respuesta del servidor no contiene mensaje');
      }

      final content = messageData['content']?.toString() ?? 'Sin respuesta';
      AppLogger.chat(
        '✅ Contenido del mensaje: ${content.length} caracteres',
        tag: 'CHAT_SERVICE',
      );

      final assistant = ChatMessage(
        id:
            messageData['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: content,
        timestamp:
            DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        model: normalizedModel,
      );

      final remaining = (res.data as Map)['remaining'];
      final limit = (res.data as Map)['limit'];
      final tier = (res.data as Map)['tier']?.toString();

      final response = ChatResponse(
        message: assistant,
        remaining: (remaining is int)
            ? remaining
            : int.tryParse(remaining?.toString() ?? ''),
        limit: (limit is int) ? limit : int.tryParse(limit?.toString() ?? ''),
        tier: tier,
      );

      AppLogger.chat(
        '✅ Respuesta procesada exitosamente: ${assistant.content.length} caracteres',
        tag: 'CHAT_SERVICE',
      );

      return response;
    } on DioException catch (error) {
      // Manejo específico de errores de Dio
      String errorMessage = 'Error al enviar mensaje';

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'El modelo está tardando más de lo esperado. '
            'Esto es normal con modelos locales. Intenta nuevamente o usa un modelo más rápido.';
        AppLogger.error(
          '⏰ Timeout esperando respuesta del modelo',
          tag: 'CHAT_SERVICE',
          error: error,
        );
      } else if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (statusCode == 403) {
          errorMessage =
              responseData?['message']?.toString() ??
              'No tienes permisos para usar este modelo.';
        } else if (statusCode == 429) {
          errorMessage =
              'Has alcanzado tu límite de mensajes. Intenta más tarde.';
        } else {
          errorMessage =
              responseData?['message']?.toString() ??
              'Error del servidor: ${statusCode ?? "desconocido"}';
        }

        AppLogger.error(
          '❌ Error del servidor: $statusCode',
          tag: 'CHAT_SERVICE',
          error: error,
        );
      } else if (error.type == DioExceptionType.connectionError) {
        errorMessage =
            'Error de conexión. Verifica tu internet e intenta nuevamente.';
        AppLogger.error(
          '🌐 Error de conexión',
          tag: 'CHAT_SERVICE',
          error: error,
        );
      } else {
        AppLogger.error(
          '❌ Error enviando mensaje',
          tag: 'CHAT_SERVICE',
          error: error,
        );
      }

      throw Exception(errorMessage);
    } catch (error) {
      AppLogger.error(
        '❌ Error inesperado enviando mensaje',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      rethrow;
    }
  }

  /// Enviar mensaje con streaming (SSE)
  /// Retorna un Stream que emite chunks de la respuesta mientras se genera
  Stream<StreamChatEvent> sendMessageStream({
    required String message,
    required String model,
    String? conversationId,
  }) async* {
    try {
      AppLogger.chat(
        '📤 Enviando mensaje con streaming: $message',
        tag: 'CHAT_SERVICE',
      );

      // Normalizar modelo
      final String normalizedModel = (model.trim().toLowerCase() == 'ollama')
          ? 'ollama-qwen2.5-coder:7b'
          : model;

      final payload = {
        'content': message,
        'model': normalizedModel,
        if (conversationId != null) 'conversationId': conversationId,
      };

      final token = await _auth.getToken();

      // Configurar timeout largo para modelos locales
      final bool isLocalModel =
          normalizedModel.toLowerCase() == 'openai' ||
          normalizedModel.toLowerCase().startsWith('ollama');
      final Duration timeout = isLocalModel
          ? const Duration(
              minutes: 10,
            ) // 10 minutos para streaming de modelos locales
          : const Duration(minutes: 5); // 5 minutos para modelos cloud

      AppLogger.chat(
        '⏱️ Timeout streaming: ${timeout.inMinutes} minutos (modelo: ${isLocalModel ? "local" : "cloud"})',
        tag: 'CHAT_SERVICE',
      );

      // Realizar petición SSE
      final response = await _dio.post(
        '/chat/message/stream',
        data: payload,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
          responseType: ResponseType.stream,
          receiveTimeout: timeout,
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      AppLogger.chat('📡 Stream iniciado', tag: 'CHAT_SERVICE');

      // Procesar stream SSE
      // En Dio, cuando responseType es stream, response.data es un ResponseBody
      // que tiene una propiedad 'stream' de tipo Stream<List<int>>
      final responseBody = response.data;
      Stream<List<int>> byteStream;

      // Intentar acceder al stream de diferentes formas según la versión de Dio
      if (responseBody is Stream<List<int>>) {
        byteStream = responseBody;
      } else {
        // En versiones recientes de Dio, response.data es un ResponseBody
        try {
          // Intentar acceder a la propiedad 'stream' usando dynamic
          final dynamic body = responseBody;
          byteStream = body.stream as Stream<List<int>>;
        } catch (e) {
          throw Exception(
            'No se pudo acceder al stream. Tipo: ${responseBody.runtimeType}, Error: $e',
          );
        }
      }

      String buffer = '';
      String fullContent = '';
      String? conversationIdFromResponse;
      int? remaining;
      int? limit;
      String? tier;

      // Transformar bytes a string chunk por chunk
      await for (final bytes in byteStream) {
        final chunk = utf8.decode(bytes, allowMalformed: true);
        buffer += chunk;

        // Procesar líneas completas (SSE termina con \n\n)
        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final dataLine = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);

          if (dataLine.startsWith('data: ')) {
            final jsonStr = dataLine
                .substring(6)
                .trim(); // Remover "data: " y espacios
            if (jsonStr.isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;

              // Procesar diferentes tipos de eventos
              if (data.containsKey('content')) {
                // Chunk de contenido
                final content = data['content'] as String? ?? '';
                if (content.isNotEmpty) {
                  fullContent += content;
                  yield StreamChatEvent.chunk(content);
                }
              } else if (data.containsKey('finished') &&
                  data['finished'] == true) {
                // Stream terminado
                conversationIdFromResponse = data['conversationId']?.toString();
                remaining = data['remaining'] as int?;
                limit = data['limit'] as int?;
                tier = data['tier']?.toString();

                AppLogger.chat(
                  '✅ Stream completado: ${fullContent.length} caracteres',
                  tag: 'CHAT_SERVICE',
                );

                // Crear mensaje final
                final assistant = ChatMessage(
                  id:
                      data['messageId']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  role: ChatRole.assistant,
                  content: fullContent,
                  timestamp: DateTime.now(),
                  model: normalizedModel,
                );

                yield StreamChatEvent.complete(
                  message: assistant,
                  conversationId: conversationIdFromResponse,
                  remaining: remaining,
                  limit: limit,
                  tier: tier,
                );
                return; // Terminar el stream
              } else if (data.containsKey('error')) {
                // Error en el stream
                final errorMsg =
                    data['message']?.toString() ?? 'Error desconocido';
                AppLogger.error(
                  '❌ Error en stream: $errorMsg',
                  tag: 'CHAT_SERVICE',
                );
                yield StreamChatEvent.error(errorMsg);
                return;
              }
            } catch (e) {
              AppLogger.error('❌ Error parseando SSE: $e', tag: 'CHAT_SERVICE');
              // Continuar procesando aunque haya un error de parsing
            }
          }
        }
      }
    } catch (error) {
      AppLogger.error(
        '❌ Error en streaming',
        tag: 'CHAT_SERVICE',
        error: error,
      );
      if (error is DioException) {
        String errorMessage = 'Error al enviar mensaje';
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          errorMessage =
              'El modelo está tardando más de lo esperado. '
              'Esto es normal con modelos locales. Intenta nuevamente.';
        } else if (error.type == DioExceptionType.badResponse) {
          errorMessage =
              error.response?.data?.toString() ?? 'Error del servidor';
        }
        yield StreamChatEvent.error(errorMessage);
      } else {
        yield StreamChatEvent.error(error.toString());
      }
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
        id:
            chatMap['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: chatMap['title']?.toString() ?? 'Nueva conversación',
        createdAt:
            DateTime.tryParse(chatMap['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(chatMap['updatedAt']?.toString() ?? '') ??
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

      // Endpoint público, no requiere autenticación
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
        id: 'ollama-qwen2.5-coder:7b',
        name: 'Qwen2.5 Coder 7B',
        provider: 'Ollama Local',
        available: true,
        isPremium: false,
        features: ['text-generation', 'code-generation', 'programming'],
        description:
            'Modelo especializado en programación y generación de código',
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
        name: 'GPT OSS 20B (LLM Studio)',
        provider: 'LLM Studio Local',
        available: true,
        isPremium: true,
        features: ['text-generation', 'streaming', 'chat-completions'],
        description:
            'Modelo local GPT OSS 20B ejecutándose en LLM Studio con sistema de colas',
        defaultModel: 'openai/gpt-oss-20b',
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

/// Eventos del stream de chat
sealed class StreamChatEvent {
  const StreamChatEvent();

  /// Chunk de contenido recibido
  const factory StreamChatEvent.chunk(String content) = StreamChunkEvent;

  /// Stream completado con mensaje final
  const factory StreamChatEvent.complete({
    required ChatMessage message,
    String? conversationId,
    int? remaining,
    int? limit,
    String? tier,
  }) = StreamCompleteEvent;

  /// Error en el stream
  const factory StreamChatEvent.error(String message) = StreamErrorEvent;
}

class StreamChunkEvent implements StreamChatEvent {
  final String content;
  const StreamChunkEvent(this.content);
}

class StreamCompleteEvent implements StreamChatEvent {
  final ChatMessage message;
  final String? conversationId;
  final int? remaining;
  final int? limit;
  final String? tier;

  const StreamCompleteEvent({
    required this.message,
    this.conversationId,
    this.remaining,
    this.limit,
    this.tier,
  });
}

class StreamErrorEvent implements StreamChatEvent {
  final String message;
  const StreamErrorEvent(this.message);
}
