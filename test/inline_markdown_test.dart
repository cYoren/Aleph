import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/inline_markdown.dart';

void main() {
  group('emphasis', () {
    test('parses bold', () {
      expect(
        parseInlineMarkdown('the word **bara** means created'),
        const [
          MarkdownRun('the word '),
          MarkdownRun('bara', bold: true),
          MarkdownRun(' means created'),
        ],
      );
    });

    test('parses italic', () {
      expect(
        parseInlineMarkdown('*shamayim* is dual'),
        const [
          MarkdownRun('shamayim', italic: true),
          MarkdownRun(' is dual'),
        ],
      );
    });

    test('keeps Hebrew and Greek inside emphasis intact', () {
      final runs = parseInlineMarkdown('**בָּרָא** and **λόγος**');
      expect(runs.first, const MarkdownRun('בָּרָא', bold: true));
      expect(runs.last, const MarkdownRun('λόγος', bold: true));
    });
  });

  group('unmatched markers', () {
    test('a lone asterisk stays literal rather than eating the rest', () {
      // A stray marker must not silently italicise everything after it.
      expect(
        parseInlineMarkdown('2 * 3 is six'),
        const [MarkdownRun('2 * 3 is six')],
      );
    });

    test('an unclosed bold marker stays literal', () {
      expect(
        parseInlineMarkdown('see **here and nothing closes it'),
        const [MarkdownRun('see **here and nothing closes it')],
      );
    });

    test('escaped markers render as themselves', () {
      expect(
        parseInlineMarkdown(r'a \*literal\* asterisk'),
        const [MarkdownRun('a *literal* asterisk')],
      );
    });
  });

  group('stripInlineMarkdown', () {
    test('removes markers, keeps text', () {
      expect(
        stripInlineMarkdown('**bara** means *created*'),
        'bara means created',
      );
    });

    test('is a no-op on plain prose', () {
      const plain = 'In the beginning God created the heavens.';
      expect(stripInlineMarkdown(plain), plain);
    });
  });

  group('edge cases', () {
    test('handles empty input', () {
      expect(parseInlineMarkdown(''), isEmpty);
      expect(stripInlineMarkdown(''), '');
    });

    test('handles backtick code', () {
      final runs = parseInlineMarkdown('use `bara` here');
      expect(runs[1], const MarkdownRun('bara', code: true));
    });
  });
}
