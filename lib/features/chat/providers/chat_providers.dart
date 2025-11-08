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
      // Agregar mensaje del usuario
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.user,
        content: message,
        timestamp: DateTime.now(),
      );

      // Crear mensaje de asistente vacío para streaming
      final assistantMessageId = DateTime.now().millisecondsSinceEpoch
          .toString();
      final assistant = ChatMessage(
        id: assistantMessageId,
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        model: model,
        isStreaming: true,
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage, assistant],
        isLoading: true,
        isStreaming: true,
        error: null,
      );

      // Actualizar conversationId si no existe
      String? conversationId = state.currentChatId;
      if (conversationId == null && state.messages.isEmpty) {
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
      await for (final event in _chatService.sendMessageStream(
        message: message,
        model: model,
        conversationId: conversationId,
      )) {
        if (event is StreamChunkEvent) {
          // Actualizar contenido del mensaje mientras llega
          fullContent += event.content;
          final updatedAssistant = assistant.copyWith(
            content: fullContent,
            isStreaming: true,
          );

          // Actualizar mensaje en la lista
          final updatedMessages = state.messages.map((msg) {
            return msg.id == assistantMessageId ? updatedAssistant : msg;
          }).toList();

          state = state.copyWith(messages: updatedMessages);
        } else if (event is StreamCompleteEvent) {
          // Stream completado - usar el contenido que ya tenemos acumulado
          // para evitar renderizar dos veces el mismo contenido
          // Solo actualizar el estado de streaming sin cambiar el contenido ni el ID
          // para evitar que Flutter trate el mensaje como nuevo
          final updatedMessages = state.messages.map((msg) {
            if (msg.id == assistantMessageId) {
              // Solo actualizar el estado de streaming, mantener todo lo demás igual
              // Esto evita que Flutter reconstruya el widget como un mensaje nuevo
              return msg.copyWith(isStreaming: false);
            }
            return msg;
          }).toList();

          state = state.copyWith(
            messages: updatedMessages,
            isLoading: false,
            isStreaming: false,
            currentChatId: event.conversationId ?? state.currentChatId,
          );

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
