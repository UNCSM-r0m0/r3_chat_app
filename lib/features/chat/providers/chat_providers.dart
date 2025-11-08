import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'models_providers.dart'; // Importar el provider desde models_providers

/// Provider para el estado del chat actual
final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(chatServiceProvider), ref);
});

/// Provider para la lista de chats
final chatListProvider = StateNotifierProvider<ChatListNotifier, List<Chat>>((
  ref,
) {
  return ChatListNotifier(ref.read(chatServiceProvider));
});

/// Notifier para manejar el estado del chat
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final Ref _ref;

  ChatNotifier(this._chatService, this._ref) : super(const ChatState());

  /// Cargar una conversación por id y establecerla como actual
  Future<void> loadChat(String chatId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final chat = await _chatService.getChat(chatId);
      final normalizedModel = (chat.model != null && chat.model == 'ollama')
          ? 'ollama-qwen2.5-coder:7b'
          : chat.model;
      state = state.copyWith(
        messages: chat.messages,
        isLoading: false,
        currentChatId: chat.id,
        selectedModel: normalizedModel ?? state.selectedModel,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  /// Enviar mensaje con streaming
  Future<void> sendMessage(String message, String model) async {
    if (message.trim().isEmpty) return;

    try {
      // Generar IDs únicos y estables por rol para evitar colisiones
      final ts = DateTime.now().microsecondsSinceEpoch;
      final userId = 'u_$ts';
      final assistantMessageId = 'a_$ts';

      // Agregar mensaje del usuario
      final userMessage = ChatMessage(
        id: userId,
        role: ChatRole.user,
        content: message,
        timestamp: DateTime.now(),
      );

      // Crear mensaje de asistente vacío para streaming
      final assistant = ChatMessage(
        id: assistantMessageId,
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        model: model,
        isStreaming: true,
      );

      // Guardar los mensajes actuales antes de agregar los nuevos
      final currentMessages = List<ChatMessage>.from(state.messages);
      final newMessages = [...currentMessages, userMessage, assistant];

      state = state.copyWith(
        messages: newMessages,
        isLoading: true,
        isStreaming: true,
        error: null,
      );

      // Verificar que el mensaje del usuario se agregó correctamente
      assert(
        state.messages.any(
          (msg) => msg.id == userMessage.id && msg.content == message,
        ),
        'El mensaje del usuario no se agregó correctamente',
      );

      // Verificar que se agregaron los dos mensajes (usuario y asistente) y que sus IDs son únicos
      assert(
        state.messages.length >= 2 &&
            state.messages[state.messages.length - 2].id == userId &&
            state.messages[state.messages.length - 2].role == ChatRole.user &&
            state.messages.last.id == assistantMessageId &&
            state.messages.last.role == ChatRole.assistant &&
            state.messages.last.id != state.messages[state.messages.length - 2].id,
        'Error al agregar mensajes iniciales o IDs duplicados (usuario/asistente)'
      );

      // Verificar IDs únicos en toda la lista
      assert(
        state.messages.map((m) => m.id).toSet().length == state.messages.length,
        'Se detectaron IDs duplicados en la lista de mensajes',
      );

      // Actualizar conversationId si no existe
      String? conversationId = state.currentChatId;
      if (conversationId == null) {
        // Crear nuevo chat si es necesario
        try {
          final newChat = await _chatService.createNewChat();
          conversationId = newChat.id;
          state = state.copyWith(currentChatId: conversationId);
        } catch (e) {
          // Si falla crear chat, continuar sin conversationId
        }
      }

      // Procesar stream
      String fullContent = '';
      bool streamCompleted = false;
      String? lastUpdatedContent; // Track del último contenido actualizado

      await for (final event in _chatService.sendMessageStream(
        message: message,
        model: model,
        conversationId: conversationId,
      )) {
        if (event is StreamChunkEvent) {
          // Actualizar contenido del mensaje mientras llega
          fullContent += event.content;

          // Verificar si el contenido realmente cambió antes de actualizar
          final currentMessage = state.messages.firstWhere(
            (msg) => msg.id == assistantMessageId,
            orElse: () => assistant,
          );

          // Solo actualizar si el contenido cambió y es diferente al último actualizado
          // Esto evita actualizaciones redundantes cuando llegan chunks vacíos o duplicados
          if (currentMessage.content != fullContent &&
              lastUpdatedContent != fullContent &&
              fullContent.isNotEmpty) {
            lastUpdatedContent = fullContent;

            final updatedAssistant = currentMessage.copyWith(
              content: fullContent,
              isStreaming: true,
            );

            // Crear nueva lista solo si el mensaje realmente cambió
            // Usar un enfoque más eficiente: buscar el índice y reemplazar solo ese elemento
            final messageIndex = state.messages.indexWhere(
              (msg) => msg.id == assistantMessageId,
            );

            if (messageIndex != -1) {
              // Crear nueva lista reemplazando solo el mensaje que cambió
              // IMPORTANTE: Preservar todos los mensajes anteriores, incluyendo el del usuario
              final messagesBefore = state.messages.take(messageIndex).toList();
              final messagesAfter = state.messages
                  .skip(messageIndex + 1)
                  .toList();

              final updatedMessages = [
                ...messagesBefore,
                updatedAssistant,
                ...messagesAfter,
              ];

              // Verificar que todos los mensajes se preservaron
              assert(
                updatedMessages.length == state.messages.length,
                'La cantidad de mensajes cambió: ${state.messages.length} -> ${updatedMessages.length}',
              );

              // Verificar que el mensaje del usuario sigue presente
              final userMsgExists = updatedMessages.any(
                (msg) => msg.role == ChatRole.user && msg.content == message,
              );
              assert(
                userMsgExists,
                'El mensaje del usuario se perdió durante la actualización',
              );

              // Verificar IDs únicos tras la actualización
              assert(
                updatedMessages.map((m) => m.id).toSet().length == updatedMessages.length,
                'IDs duplicados detectados tras actualizar chunk',
              );

              state = state.copyWith(messages: updatedMessages);
            }
          }
        } else if (event is StreamCompleteEvent) {
          // Stream completado - evitar actualizar si ya se completó
          if (streamCompleted) {
            // Ya se procesó, salir inmediatamente
            break;
          }
          streamCompleted = true;

          // Verificar si el contenido del mensaje actual ya coincide con el contenido completo
          final currentMessage = state.messages.firstWhere(
            (msg) => msg.id == assistantMessageId,
            orElse: () => assistant,
          );

          // Solo actualizar si realmente es necesario
          // Comparar contenido y estado de streaming
          final contentChanged = currentMessage.content != fullContent;
          final streamingChanged = currentMessage.isStreaming != false;
          final needsMessageUpdate = contentChanged || streamingChanged;

          if (needsMessageUpdate) {
            // Actualizar solo el mensaje específico sin crear una nueva lista completa
            final messageIndex = state.messages.indexWhere(
              (msg) => msg.id == assistantMessageId,
            );

            if (messageIndex != -1) {
              // Crear nueva lista reemplazando solo el mensaje que cambió
              // IMPORTANTE: Preservar todos los mensajes anteriores, incluyendo el del usuario
              final messagesBefore = state.messages.take(messageIndex).toList();
              final messagesAfter = state.messages
                  .skip(messageIndex + 1)
                  .toList();

              final updatedMessage = state.messages[messageIndex].copyWith(
                content: fullContent,
                isStreaming: false,
              );

              final updatedMessages = [
                ...messagesBefore,
                updatedMessage,
                ...messagesAfter,
              ];

              // Verificar que todos los mensajes se preservaron
              assert(
                updatedMessages.length == state.messages.length,
                'La cantidad de mensajes cambió al completar: ${state.messages.length} -> ${updatedMessages.length}',
              );

              // Verificar que el mensaje del usuario sigue presente
              final userMsgExists = updatedMessages.any(
                (msg) => msg.role == ChatRole.user && msg.content == message,
              );
              assert(
                userMsgExists,
                'El mensaje del usuario se perdió al completar el stream',
              );

              // Verificar IDs únicos tras completar
              assert(
                updatedMessages.map((m) => m.id).toSet().length == updatedMessages.length,
                'IDs duplicados detectados al completar el stream',
              );

              // Actualizar estado en una sola operación
              state = state.copyWith(
                messages: updatedMessages,
                isLoading: false,
                isStreaming: false,
                currentChatId: event.conversationId ?? state.currentChatId,
              );
            } else {
              // Si no se encuentra el mensaje, solo actualizar el estado general
              state = state.copyWith(
                isLoading: false,
                isStreaming: false,
                currentChatId: event.conversationId ?? state.currentChatId,
              );
            }
          } else {
            // El contenido ya está actualizado, solo cambiar el estado general
            // sin tocar los mensajes para evitar reconstrucciones innecesarias
            state = state.copyWith(
              isLoading: false,
              isStreaming: false,
              currentChatId: event.conversationId ?? state.currentChatId,
            );
          }

          // Actualizar uso y plan
          if (event.limit != null && event.remaining != null) {
            final used = (event.limit! - event.remaining!).clamp(
              0,
              event.limit!,
            );
            _ref
                .read(authStateProvider.notifier)
                .updateUsage(used: used, limit: event.limit!);
          }
          if (event.tier != null) {
            _ref
                .read(authStateProvider.notifier)
                .setIsPro(event.tier!.toUpperCase() == 'PREMIUM');
          }
          break;
        } else if (event is StreamErrorEvent) {
          // Error en el stream
          state = state.copyWith(
            isLoading: false,
            isStreaming: false,
            error: event.message,
          );
          // Remover mensaje de asistente vacío
          state = state.copyWith(
            messages: state.messages
                .where((msg) => msg.id != assistantMessageId)
                .toList(),
          );
          break;
        }
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isStreaming: false,
        error: error.toString(),
      );
    }
  }

  /// Limpiar chat
  void clearChat() {
    state = const ChatState();
  }

  /// Seleccionar modelo
  void selectModel(String model) {
    state = state.copyWith(selectedModel: model);
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Notifier para manejar la lista de chats
class ChatListNotifier extends StateNotifier<List<Chat>> {
  final ChatService _chatService;

  ChatListNotifier(this._chatService) : super([]);

  /// Cargar historial de chats
  Future<void> loadChats() async {
    try {
      final chats = await _chatService.getChatHistory();
      state = chats;
    } catch (error) {
      // Manejar error
    }
  }

  /// Crear nuevo chat
  Future<Chat> createNewChat() async {
    try {
      final chat = await _chatService.createNewChat();
      state = [chat, ...state];
      return chat;
    } catch (error) {
      rethrow;
    }
  }

  /// Eliminar chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      state = state.where((chat) => chat.id != chatId).toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Actualizar chat
  void updateChat(Chat updatedChat) {
    state = state.map((chat) {
      return chat.id == updatedChat.id ? updatedChat : chat;
    }).toList();
  }
}
