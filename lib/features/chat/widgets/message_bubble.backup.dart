import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

/// Widget para mostrar un mensaje en el chat
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6), // purple-600
                          Color(0xFFEC4899), // pink-600
                        ],
                      )
                    : null,
                color: isUser ? null : const Color(0xFF374151), // gray-700
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(),
                  const SizedBox(height: 4),
                  _buildTimestamp(),
                ],
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 12), _buildAvatar()],
        ],
      ),
    );
  }

  /// Widget para el avatar del usuario/IA
  Widget _buildAvatar() {
    final isUser = message.role == ChatRole.user;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6), // purple-600
                  Color(0xFFEC4899), // pink-600
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B7280), // gray-500
                  Color(0xFF4B5563), // gray-600
                ],
              ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  /// Widget para el contenido del mensaje
  Widget _buildMessageContent() {
    final isUser = message.role == ChatRole.user;

    if (isUser) {
      return Text(
        message.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    } else {
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          code: const TextStyle(
            backgroundColor: Color(0xFF1F2937), // gray-800
            color: Color(0xFFF3F4F6), // gray-100
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF1F2937), // gray-800
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: const TextStyle(
            color: Color(0xFF9CA3AF), // gray-400
            fontStyle: FontStyle.italic,
          ),
          listBullet: const TextStyle(color: Colors.white),
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          h3: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          a: const TextStyle(
            color: Color(0xFF8B5CF6), // purple-500
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
  }

  /// Widget para el timestamp
  Widget _buildTimestamp() {
    final isUser = message.role == ChatRole.user;
    final time = _formatTime(message.timestamp);

    return Text(
      time,
      style: TextStyle(
        color: isUser
            ? Colors.white.withOpacity(0.7)
            : const Color(0xFF9CA3AF), // gray-400
        fontSize: 11,
      ),
    );
  }

  /// Formatear tiempo
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

