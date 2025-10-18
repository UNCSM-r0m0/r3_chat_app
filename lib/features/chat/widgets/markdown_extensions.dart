import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart' as atom_one_dark;
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Utilidades para mejorar la presentación de Markdown en móvil
/// - Bloques de código con resaltado + botón copiar
/// - Soporte para matemática (```math ...``` y $inline$)

/// Preprocesa el texto Markdown para detectar expresiones matemáticas comunes
/// y convertirlas a una forma que los builders puedan manejar fácilmente.
String preprocessMarkdownForMath(String input) {
  String text = input;

  // 1) $$ ... $$ a bloque math
  final RegExp blockDollar = RegExp(r"\$\$(.*?)\$\$", dotAll: true);
  text = text.replaceAllMapped(blockDollar, (m) => '```math\n${m[1]!.trim()}\n```');

  // 2) \[ ... \] a bloque math
  final RegExp bracketBlock = RegExp(r"\\\[(.*?)\\\]", dotAll: true);
  text = text.replaceAllMapped(bracketBlock, (m) => '```math\n${m[1]!.trim()}\n```');

  return text;
}

/// InlineSyntax para capturar $ ... $ como matemática inline.
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(r"\$(.+?)\$");

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final String body = match.group(1) ?? '';
    parser.addNode(md.Element.text('math-inline', body));
    return true;
  }
}

/// Builder para renderizar matemática en línea usando flutter_math_fork.
class MathInlineBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String tex = element.textContent.trim();
    return Baseline(
      baseline: (preferredStyle?.fontSize ?? 14) * 1.1,
      baselineType: TextBaseline.alphabetic,
      child: Math.tex(
        tex,
        mathStyle: MathStyle.text,
        textStyle: (preferredStyle ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

/// Builder para <pre> (bloques de código). Si el lenguaje es `math`,
/// renderiza LaTeX; si no, usa resaltado de sintaxis y botón copiar.
class PreCodeBlockBuilder extends MarkdownElementBuilder {
  String? _language;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) {
    final md.Element? codeElem = element.children != null && element.children!.isNotEmpty
        ? element.children!.first as md.Element?
        : null;
    if (codeElem != null) {
      final String? klass = codeElem.attributes['class'];
      if (klass != null && klass.startsWith('language-')) {
        _language = klass.substring('language-'.length);
      } else {
        _language = null;
      }
    } else {
      _language = null;
    }
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final String raw = text.text;
    final String? lang = _language;

    if (lang != null && lang.toLowerCase() == 'math') {
      return _MathBlock(tex: raw.trim());
    }
    return _CodeBlock(code: raw, language: lang);
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code, this.language});
  final String code;
  final String? language;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;
  late final ScrollController _hController;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  void initState() {
    super.initState();
    _hController = ScrollController();
  }

  @override
  void dispose() {
    _hController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Scrollbar(
            thumbVisibility: true,
            controller: _hController,
            child: SingleChildScrollView(
              controller: _hController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: HighlightView(
                widget.code,
                // Asegura un lenguaje por defecto para evitar excepciones
                language: (widget.language == null || widget.language!.trim().isEmpty)
                    ? 'plaintext'
                    : widget.language!.trim(),
                theme: atom_one_dark.atomOneDarkTheme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _copy,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_copied ? Icons.check : Icons.copy,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _copied ? 'Copiado' : 'Copiar',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MathBlock extends StatelessWidget {
  const _MathBlock({required this.tex});
  final String tex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          tex,
          mathStyle: MathStyle.display,
          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
