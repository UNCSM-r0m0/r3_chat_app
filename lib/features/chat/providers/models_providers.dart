import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/ai_model.dart';

/// Provider para el servicio de chat (reutilizado desde chat_providers)
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Provider para obtener los modelos disponibles
final availableModelsProvider = FutureProvider<List<AIModel>>((ref) async {
  try {
    final chatService = ref.read(chatServiceProvider);
    return await chatService.getAvailableModels();
  } catch (error) {
    // En caso de error, devolver lista vacía para evitar crashes
    return [];
  }
});

/// Provider para el estado de carga de los modelos
final availableModelsStateProvider =
    StateNotifierProvider<AvailableModelsNotifier, AsyncValue<List<AIModel>>>((
      ref,
    ) {
      return AvailableModelsNotifier(ref.read(chatServiceProvider));
    });

/// Notifier para manejar el estado de los modelos disponibles
class AvailableModelsNotifier extends StateNotifier<AsyncValue<List<AIModel>>> {
  final ChatService _chatService;

  AvailableModelsNotifier(this._chatService)
    : super(const AsyncValue.loading()) {
    loadModels();
  }

  /// Cargar modelos disponibles
  Future<void> loadModels() async {
    try {
      state = const AsyncValue.loading();
      final models = await _chatService.getAvailableModels();
      state = AsyncValue.data(models);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refrescar modelos
  Future<void> refresh() async {
    await loadModels();
  }

  /// Obtener modelo por ID
  AIModel? getModelById(String id) {
    return state.when(
      data: (models) => models.firstWhere(
        (model) => model.id == id,
        orElse: () => throw StateError('Model not found'),
      ),
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// Obtener modelos disponibles para el usuario (filtrados por tier)
  List<AIModel> getAvailableModelsForUser(bool isPro) {
    return state.when(
      data: (models) =>
          models.where((model) => !model.isPremium || isPro).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Obtener el modelo por defecto dinámicamente basado en los modelos disponibles
  String? getDefaultModelId(bool isPro) {
    return state.when(
      data: (models) {
        // Filtrar modelos disponibles según el tier del usuario
        final availableModels = models
            .where((model) => model.available && (!model.isPremium || isPro))
            .toList();

        if (availableModels.isEmpty) return null;

        // Priorizar modelos no premium, luego premium
        final freeModels = availableModels.where((m) => !m.isPremium).toList();
        if (freeModels.isNotEmpty) {
          return freeModels.first.id;
        }

        // Si no hay modelos gratuitos y el usuario es Pro, usar el primero disponible
        return availableModels.first.id;
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }
}
