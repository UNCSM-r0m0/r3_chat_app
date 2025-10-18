import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../../auth/providers/auth_providers.dart';

/// Provider para el servicio de chat
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

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

  /// Enviar mensaje
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

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        error: null,
      );

      // Enviar al servicio
      final response = await _chatService.sendMessage(
        message: message,
        model: model,
        conversationId: state.currentChatId,
      );

      // Agregar respuesta
      final assistant = response.message;
      state = state.copyWith(
        messages: [...state.messages, assistant],
        isLoading: false,
      );

      // Actualizar uso y plan si vienen en la respuesta
      if (response.limit != null && response.remaining != null) {
        final used = (response.limit! - response.remaining!).clamp(0, response.limit!);
        _ref.read(authStateProvider.notifier).updateUsage(used: used, limit: response.limit!);
      }
      if (response.tier != null) {
        _ref.read(authStateProvider.notifier).setIsPro(response.tier!.toUpperCase() == 'PREMIUM');
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
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
