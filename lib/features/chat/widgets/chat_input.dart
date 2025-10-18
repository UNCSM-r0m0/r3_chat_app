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
      if (mounted) setState(() {});
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

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
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
              // Selector de modelo
              if (_showModelSelector) ...[
                const ModelSelector(),
                const SizedBox(height: 12),
              ],

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
                          // Botón de modelo
                          _buildModelButton(),
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
    final selectedModel = chatState.selectedModel ?? (isPro ? 'deepseek' : 'ollama');

    return GestureDetector(
      onTap: () {
        if (!isPro) return; // Solo Pro puede cambiar modelo
        setState(() {
          _showModelSelector = !_showModelSelector;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4B5563), // gray-600
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6B7280), // gray-500
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
            Text(
              selectedModel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isPro ? Icons.keyboard_arrow_down : Icons.lock_outline,
              color: Colors.white,
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
