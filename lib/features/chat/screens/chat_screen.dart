import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/chat_area.dart';
import '../widgets/chat_input.dart';
import '../providers/chat_providers.dart';

/// Pantalla principal del chat
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar historial de chats al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatListProvider.notifier).loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // gray-900
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Área de chat
          Expanded(child: ChatArea()),

          // Input de chat
          const ChatInput(),
        ],
      ),

      // Mostrar error si existe
      floatingActionButton: chatState.error != null
          ? _buildErrorFloatingActionButton()
          : null,
    );
  }

  /// Construir AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1F2937), // gray-800
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6), // purple-500
                  Color(0xFFEC4899), // pink-500
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'R3.chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Botón de nuevo chat
        IconButton(
          onPressed: _createNewChat,
          icon: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Nuevo chat',
        ),

        // Botón de menú
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 8),
                  Text('Limpiar chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('Configuración'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Construir botón flotante de error
  Widget _buildErrorFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        ref.read(chatStateProvider.notifier).clearError();
      },
      backgroundColor: Colors.red,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      label: const Text('Error', style: TextStyle(color: Colors.white)),
    );
  }

  /// Crear nuevo chat
  void _createNewChat() async {
    try {
      await ref.read(chatListProvider.notifier).createNewChat();
      ref.read(chatStateProvider.notifier).clearChat();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuevo chat creado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creando chat: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Manejar acciones del menú
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _clearChat();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  /// Limpiar chat actual
  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar chat'),
        content: const Text('¿Estás seguro de que quieres limpiar este chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatStateProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar configuración
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Text('Configuración no disponible aún'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
