import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../../auth/providers/auth_providers.dart';
import 'model_selector.dart';

/// Widget para el input de chat
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showModelSelector = false;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios para habilitar/deshabilitar el botón enviar y refrescar UI
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          // Ocultar el selector de modelo cuando el usuario empiece a escribir
          if (_controller.text.isNotEmpty && _showModelSelector) {
            _showModelSelector = false;
          }
        });
      }
    });

    // Escuchar cambios en el foco para ocultar el selector cuando el teclado esté activo
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          // Si el campo pierde el foco, ocultar el selector
          if (!_focusNode.hasFocus) {
            _showModelSelector = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);
    final isLoading = chatState.isLoading;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final effectiveInset = bottomInset.clamp(0.0, 24.0).toDouble();
    final isKeyboardVisible = bottomInset > 0;

    // Ocultar el selector de modelo cuando el teclado esté visible
    final shouldShowModelSelector = _showModelSelector && !isKeyboardVisible;

    return SafeArea(
      top: false,
      bottom: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: effectiveInset),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2937), // gray-800
            border: Border(
              top: BorderSide(
                color: Color(0xFF374151), // gray-700
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Selector de modelo con animación
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: shouldShowModelSelector ? null : 0,
                child: shouldShowModelSelector
                    ? Column(
                        children: [
                          ModelSelector(
                            onSelected: () {
                              if (mounted) {
                                setState(() => _showModelSelector = false);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // Input principal
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF374151), // gray-700
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF4B5563), // gray-600
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Área de texto
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !isLoading,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF), // gray-400
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),

                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          // Botón de modelo (flexible para evitar overflow)
                          Flexible(child: _buildModelButton()),
                          const SizedBox(width: 8),

                          // Botón de adjuntar
                          _buildAttachButton(),
                          const SizedBox(width: 8),

                          // Botón de búsqueda web
                          _buildWebSearchButton(),

                          const Spacer(),

                          // Botón de enviar
                          _buildSendButton(isLoading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón para seleccionar modelo
  Widget _buildModelButton() {
    final chatState = ref.watch(chatStateProvider);
    final isPro = ref.watch(authStateProvider).isPro;
    final selectedModel =
        chatState.selectedModel ?? (isPro ? 'deepseek' : 'ollama');

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return GestureDetector(
      onTap: () {
        if (!isPro || isKeyboardVisible)
          return; // Solo Pro puede cambiar modelo y no cuando el teclado está visible
        setState(() {
          _showModelSelector = !_showModelSelector;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isKeyboardVisible
              ? const Color(
                  0xFF374151,
                ) // gray-700 cuando el teclado está visible
              : const Color(0xFF4B5563), // gray-600
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isKeyboardVisible
                ? const Color(
                    0xFF4B5563,
                  ) // gray-600 cuando el teclado está visible
                : const Color(0xFF6B7280), // gray-500
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _getShortModelName(selectedModel),
                style: TextStyle(
                  color: isKeyboardVisible ? Colors.white70 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isKeyboardVisible
                  ? Icons.keyboard_hide
                  : (isPro ? Icons.keyboard_arrow_down : Icons.lock_outline),
              color: isKeyboardVisible ? Colors.white70 : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Botón para adjuntar archivos
  Widget _buildAttachButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5563), // gray-600
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B7280), // gray-500
          width: 1,
        ),
      ),
      child: const Icon(Icons.attach_file, color: Colors.white, size: 16),
    );
  }

  /// Botón para búsqueda web
  Widget _buildWebSearchButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5563), // gray-600
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B7280), // gray-500
          width: 1,
        ),
      ),
      child: const Icon(Icons.language, color: Colors.white, size: 16),
    );
  }

  /// Botón para enviar mensaje
  Widget _buildSendButton(bool isLoading) {
    final hasText = _controller.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasText && !isLoading ? _sendMessage : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: hasText && !isLoading
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6), // purple-600
                    Color(0xFFEC4899), // pink-600
                  ],
                )
              : null,
          color: hasText && !isLoading
              ? null
              : const Color(0xFF4B5563), // gray-600
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }

  /// Obtener nombre corto del modelo para mostrar en el botón
  String _getShortModelName(String modelId) {
    // Mapeo de nombres cortos para modelos conocidos
    switch (modelId) {
      case 'ollama-qwen2.5-coder:7b':
        return 'Qwen2.5 Coder';
      case 'ollama-deepseek-r1:7b':
        return 'DeepSeek R1';
      case 'gemini':
        return 'Gemini 2.0';
      case 'openai':
        return 'GPT-4o Mini';
      case 'deepseek':
        return 'DeepSeek Chat';
      default:
        // Para modelos desconocidos, truncar inteligentemente
        if (modelId.startsWith('ollama-')) {
          return modelId.replaceFirst('ollama-', '').split(':')[0];
        }
        return modelId.length > 15 ? '${modelId.substring(0, 12)}...' : modelId;
    }
  }

  /// Enviar mensaje
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatState = ref.read(chatStateProvider);
    final isPro = ref.read(authStateProvider).isPro;
    final model = chatState.selectedModel ?? (isPro ? 'deepseek' : 'ollama');

    ref.read(chatStateProvider.notifier).sendMessage(text, model);
    _controller.clear();
    _focusNode.requestFocus();
  }
}
