/// A very small inline-markdown renderer.
///
/// The models return `**bold**` and `*italic*` — used mostly to set off the
/// original-language words, which is exactly the emphasis we want to keep. A
/// plain `Text` widget shows the asterisks literally, so the reader sees
/// `**bara**` instead of **bara**.
///
/// This handles only what actually shows up in explanations: bold, italic, and
/// backtick code. That is a deliberate limit — a full markdown package brings
/// block layout, links, images, and its own typography, none of which belong
/// in a 150-word paragraph, and one of which (links) would be a way for model
/// output to point a reader somewhere we did not choose.
library;

import 'package:flutter/widgets.dart';

/// One run of text with its emphasis.
class MarkdownRun {
  const MarkdownRun(this.text, {this.bold = false, this.italic = false, this.code = false});

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  @override
  String toString() =>
      'MarkdownRun("$text", bold: $bold, italic: $italic, code: $code)';

  @override
  bool operator ==(Object other) =>
      other is MarkdownRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code;

  @override
  int get hashCode => Object.hash(text, bold, italic, code);
}

/// Splits [source] into emphasis runs.
///
/// Unmatched markers are treated as ordinary characters rather than swallowed,
/// so a stray asterisk in an answer never eats the rest of the paragraph.
List<MarkdownRun> parseInlineMarkdown(String source) {
  if (source.isEmpty) return const [];

  final runs = <MarkdownRun>[];
  final buffer = StringBuffer();

  var bold = false;
  var italic = false;
  var code = false;

  void flush() {
    if (buffer.isEmpty) return;
    runs.add(
      MarkdownRun(buffer.toString(), bold: bold, italic: italic, code: code),
    );
    buffer.clear();
  }

  var i = 0;
  while (i < source.length) {
    final rest = source.length - i;

    // Escaped marker: \* is a literal asterisk.
    if (source[i] == r'\' && rest > 1) {
      final next = source[i + 1];
      if (next == '*' || next == '_' || next == '`' || next == r'\') {
        buffer.write(next);
        i += 2;
        continue;
      }
    }

    if (!code && rest >= 2 && source.startsWith('**', i)) {
      // Only open a bold run when there is a closing marker to match.
      if (bold || source.indexOf('**', i + 2) != -1) {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
      // Unmatched `**`: emit both asterisks literally and step over them. If
      // we fell through, the single-asterisk branch below would see the second
      // asterisk of this pair as a closing marker and italicise the rest.
      buffer.write('**');
      i += 2;
      continue;
    }

    if (!code && source[i] == '*') {
      if (italic || source.indexOf('*', i + 1) != -1) {
        flush();
        italic = !italic;
        i += 1;
        continue;
      }
    }

    if (source[i] == '`') {
      if (code || source.indexOf('`', i + 1) != -1) {
        flush();
        code = !code;
        i += 1;
        continue;
      }
    }

    buffer.write(source[i]);
    i += 1;
  }

  flush();
  return runs;
}

/// Builds a [TextSpan] tree from inline markdown.
///
/// [baseStyle] carries the paragraph's size, colour, and line height; emphasis
/// is layered on top so the caller keeps control of typography.
TextSpan inlineMarkdownSpan(
  String source, {
  required TextStyle baseStyle,
  TextStyle? codeStyle,
}) {
  final runs = parseInlineMarkdown(source);

  return TextSpan(
    style: baseStyle,
    children: [
      for (final run in runs)
        TextSpan(
          text: run.text,
          style: run.code
              ? (codeStyle ?? baseStyle)
              : baseStyle.copyWith(
                  fontWeight: run.bold ? FontWeight.w700 : null,
                  fontStyle: run.italic ? FontStyle.italic : null,
                ),
        ),
    ],
  );
}

/// Strips markers without rendering, for places that need plain text — the
/// quality checks in `explain_health.dart`, or sharing an explanation.
String stripInlineMarkdown(String source) =>
    parseInlineMarkdown(source).map((r) => r.text).join();
