import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/models_providers.dart';
import '../models/ai_model.dart';
import '../../auth/providers/auth_providers.dart';

/// Widget para seleccionar modelo de IA
class ModelSelector extends ConsumerWidget {
  const ModelSelector({super.key, this.onSelected});

  // Se llama al seleccionar un modelo para cerrar el selector
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatStateProvider);
    final authState = ref.watch(authStateProvider);
    final isPro = authState.isPro;
    final modelsAsync = ref.watch(availableModelsProvider);

    // Obtener modelo por defecto dinámicamente
    final defaultModelId = ref
        .read(availableModelsStateProvider.notifier)
        .getDefaultModelId(isPro);
    final selectedModel =
        chatState.selectedModel ?? defaultModelId ?? 'ollama-qwen2.5-coder:7b';

    // Debug: Log del estado de autenticación
    print('🔍 ModelSelector - isPro: $isPro, user: ${authState.user?.email}');

    // Forzar actualización de modelos cuando cambie el estado de autenticación
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.isPro != next.isPro) {
        print('🔄 Estado Pro cambió: ${previous?.isPro} -> ${next.isPro}');
        // Refrescar modelos cuando cambie el estado Pro
        ref.read(availableModelsStateProvider.notifier).refresh();
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // gray-700
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4B5563), // gray-600
          width: 1,
        ),
      ),
      child: modelsAsync.when(
        data: (models) => _buildModelsList(models, selectedModel, isPro, ref),
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error, stackTrace, ref),
      ),
    );
  }

  /// Construir lista de modelos disponibles
  Widget _buildModelsList(
    List<AIModel> models,
    String selectedModel,
    bool isPro,
    WidgetRef ref,
  ) {
    // Debug: Log de modelos y filtrado
    print('🔍 Modelos totales: ${models.length}');
    print('🔍 isPro: $isPro');
    for (final model in models) {
      print(
        '🔍 Modelo: ${model.name} - isPremium: ${model.isPremium} - available: ${model.available}',
      );
    }

    // Filtrar modelos según el tier del usuario
    final availableModels = models
        .where((model) => !model.isPremium || isPro)
        .toList();

    print('🔍 Modelos filtrados: ${availableModels.length}');

    if (availableModels.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text(
              'No hay modelos disponibles',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                print('🔄 Forzando actualización de estado Pro...');
                // Forzar actualización del estado Pro
                ref.read(authStateProvider.notifier).setIsPro(true);
                // Refrescar modelos
                ref.read(availableModelsStateProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
              ),
              child: const Text('Debug: Forzar Pro'),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableModels
          .map((model) => _buildModelOptionMinimal(model, selectedModel, ref))
          .toList(),
    );
  }

  /// Construir estado de carga
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      ),
    );
  }

  /// Versión minimalista de la opción de modelo
  Widget _buildModelOptionMinimal(
    AIModel model,
    String selectedModel,
    WidgetRef ref,
  ) {
    final isSelected = selectedModel == model.id;
    final isUnavailable = !model.available;

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () {
              ref.read(chatStateProvider.notifier).selectModel(model.id);
              onSelected?.call();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isUnavailable
              ? const Color(0xFF2D3748)
              : isSelected
              ? _getModelColor(model.id).withOpacity(0.2)
              : const Color(0xFF4B5563),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnavailable
                ? const Color(0xFF4A5568)
                : isSelected
                ? _getModelColor(model.id)
                : const Color(0xFF6B7280),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isUnavailable ? Colors.grey : _getModelColor(model.id),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              model.name,
              style: TextStyle(
                color: isUnavailable
                    ? Colors.white54
                    : isSelected
                    ? _getModelColor(model.id)
                    : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Construir estado de error
  Widget _buildErrorState(Object error, StackTrace? stackTrace, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Error cargando modelos',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Refrescar modelos en caso de error
                ref.read(availableModelsStateProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener color del modelo según su ID (dinámico)
  Color _getModelColor(String modelId) {
    // Colores para modelos específicos conocidos
    if (modelId.startsWith('ollama-')) {
      // Modelos de Ollama locales - verde
      return Colors.green;
    } else if (modelId.contains('gemini')) {
      // Modelos de Google - azul
      return Colors.blue;
    } else if (modelId.contains('gpt') || modelId.contains('openai')) {
      // Modelos de OpenAI - púrpura
      return Colors.purple;
    } else if (modelId.contains('deepseek')) {
      // Modelos de DeepSeek - naranja
      return Colors.orange;
    } else if (modelId.contains('llama')) {
      // Modelos de Llama - amarillo
      return Colors.yellow;
    } else if (modelId.contains('qwen')) {
      // Modelos de Qwen - cian
      return Colors.cyan;
    } else {
      // Color por defecto para modelos desconocidos
      return Colors.grey;
    }
  }
}
