import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';

void main() {
  group('Search query normalization', () {
    test('builds unicode-friendly case variants for Cyrillic input', () {
      final variants = buildSearchQueryVariants('Бог');
      expect(variants, contains('Бог'));
      expect(variants, contains('бог'));
      expect(variants, contains('БОГ'));
    });

    test('deduplicates and trims variants', () {
      final variants = buildSearchQueryVariants('  god  ');
      expect(variants.first, equals('god'));
      expect(variants.toSet().length, equals(variants.length));
    });

    test('escapes SQL LIKE special characters safely', () {
      final escaped = escapeLikePattern(r'100%\_match');
      expect(escaped, equals(r'100\%\\\_match'));
    });
  });
}
