import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../services/chat_service.dart';

/// Widget para seleccionar modelo de IA
class ModelSelector extends ConsumerWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatStateProvider);
    final isPro = ref.watch(authStateProvider).isPro;
    final selectedModel = chatState.selectedModel ?? (isPro ? 'deepseek' : 'ollama');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // gray-700
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4B5563), // gray-600
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Modelo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildModelOptions(selectedModel, ref),
          ),
        ],
      ),
    );
  }

  /// Construir opciones de modelos
  List<Widget> _buildModelOptions(String selectedModel, WidgetRef ref) {
    final chatService = ChatService();
    final isPro = ref.read(authStateProvider).isPro;
    final availableModels = isPro ? chatService.getAvailableModels() : ['ollama'];

    final modelConfigs = {
      'ollama': _ModelOption(
        id: 'ollama',
        name: 'Ollama',
        description: 'Local y rápido',
        isPremium: false,
        color: Colors.green,
      ),
      'gemini': _ModelOption(
        id: 'gemini',
        name: 'Gemini',
        description: 'Google AI',
        isPremium: false,
        color: Colors.blue,
      ),
      'openai': _ModelOption(
        id: 'openai',
        name: 'OpenAI',
        description: 'GPT models',
        isPremium: true,
        color: Colors.purple,
      ),
      'deepseek': _ModelOption(
        id: 'deepseek',
        name: 'DeepSeek',
        description: 'Avanzado',
        isPremium: false,
        color: Colors.orange,
      ),
    };

    final models = availableModels
        .map((modelId) => modelConfigs[modelId])
        .where((model) => model != null)
        .cast<_ModelOption>()
        .toList();

    return models.map((model) {
      final isSelected = selectedModel == model.id;

      return GestureDetector(
        onTap: () {
          ref.read(chatStateProvider.notifier).selectModel(model.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? model.color.withOpacity(0.2)
                : const Color(0xFF4B5563), // gray-600
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? model.color
                  : const Color(0xFF6B7280), // gray-500
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
                  color: model.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                model.name,
                style: TextStyle(
                  color: isSelected ? model.color : Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (model.isPremium) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 12),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// Clase para representar una opción de modelo
class _ModelOption {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final Color color;

  const _ModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.isPremium,
    required this.color,
  });
}
