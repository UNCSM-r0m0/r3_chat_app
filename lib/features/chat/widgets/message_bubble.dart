import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'markdown_extensions.dart';
import '../models/chat_message.dart';

/// Widget para mostrar un mensaje en el chat
/// Usa StatefulWidget para controlar mejor las actualizaciones y evitar doble renderizado
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late ChatMessage _currentMessage;

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.message;
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Asegurar sincronización del mensaje con el widget y reconstruir cuando
    // cambian id, contenido o isStreaming (para reflejar estado de stream)
    final idChanged = oldWidget.message.id != widget.message.id;
    final contentChanged = oldWidget.message.content != widget.message.content;
    final streamingChanged =
        (oldWidget.message.isStreaming ?? false) !=
        (widget.message.isStreaming ?? false);

    if (idChanged || contentChanged || streamingChanged) {
      setState(() {
        _currentMessage = widget.message;
      });
    } else {
      // Mantener sincronizado sin forzar un rebuild
      _currentMessage = widget.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _currentMessage;
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
    final isUser = _currentMessage.role == ChatRole.user;

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
    final isUser = _currentMessage.role == ChatRole.user;

    if (isUser) {
      return Text(
        _currentMessage.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    } else {
      final mermaidMatch = RegExp(
        r'```mermaid\s+([\s\S]*?)```',
        multiLine: true,
      ).firstMatch(_currentMessage.content);
      if (mermaidMatch != null) {
        final diagram = mermaidMatch.group(1) ?? '';
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFF1F2937))
          ..loadHtmlString(_mermaidHtml(diagram));

        return SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WebViewWidget(controller: controller),
          ),
        );
      }

      // Usar RepaintBoundary y key para evitar reconstrucciones innecesarias
      // cuando solo cambia el estado de streaming
      return RepaintBoundary(
        child: MarkdownBody(
          key: ValueKey(
            'markdown_${_currentMessage.id}_${_currentMessage.content.hashCode}',
          ),
          data: preprocessMarkdownForMath(_currentMessage.content),
          inlineSyntaxes: [MathInlineSyntax()],
          builders: {
            'pre': PreCodeBlockBuilder(),
            'math-inline': MathInlineBuilder(),
          },
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
        ),
      );
    }
  }

  String _mermaidHtml(String code) {
    // HTML mínimo para renderizar mermaid en WebView móvil
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style> body{margin:0;background:#111;color:#eee} .m{padding:8px} </style>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({ startOnLoad: true, theme: 'dark' });</script>
  </head>
<body>
  <div class="m">
    <div class="mermaid">
${code}
    </div>
  </div>
</body>
</html>
''';
  }

  /// Widget para el timestamp
  Widget _buildTimestamp() {
    final isUser = _currentMessage.role == ChatRole.user;
    final time = _formatTime(_currentMessage.timestamp);

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
