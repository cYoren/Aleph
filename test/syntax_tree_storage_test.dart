import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/real_syntax_node.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The release database stores syntax trees as one gzip block per book
/// (`scripts/prepare_bible_db.py`). These cover the block layout and the whole
/// path from the shipped asset to parsed trees.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  /// Joins records the way the build does: NUL separated.
  String block(List<String> records) => records.join('\u0000');

  group('syntax tree block layout', () {
    test('records parse into chapter:verse keys', () {
      expect(
        parseSyntaxTreeBlock(block(['1:1\t[{"c":"cl"}]', '1:2\t[{"c":"np"}]'])),
        {'1:1': '[{"c":"cl"}]', '1:2': '[{"c":"np"}]'},
      );
    });

    test('unicode survives intact', () {
      expect(parseSyntaxTreeBlock(block(['2:1\t[{"t":"בָּרָ֣א"}]'])), {
        '2:1': '[{"t":"בָּרָ֣א"}]',
      });
    });

    test('a tab inside the document is not a second delimiter', () {
      // Real MACULA JSON is minified, but the parser must still split on the
      // first tab only.
      expect(parseSyntaxTreeBlock(block(['1:1\t[{"t":"a\tb"}]'])), {
        '1:1': '[{"t":"a\tb"}]',
      });
    });

    test('empty records are ignored and unknown verses are absent', () {
      final parsed = parseSyntaxTreeBlock(block(['', '1:1\t[]', '', '']));
      expect(parsed, {'1:1': '[]'});
      expect(parsed['9:9'], isNull);
    });

    test('an empty block yields nothing rather than throwing', () {
      expect(parseSyntaxTreeBlock(''), isEmpty);
    });
  });

  group('bundled database', () {
    test('only the packed asset ships, never the raw build artifact', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundled = manifest.listAssets().toSet();
      expect(bundled, contains('assets/bible.db.gz'));
      expect(
        bundled,
        isNot(contains('assets/bible.db')),
        reason: 'the raw database must not travel with the app',
      );
    });

    test('every book resolves real trees through the shipped asset', () async {
      // Exercises the unpack path (assets/bible.db.gz) and the compacted
      // reader end to end.
      final dao = BibleDAO();
      final raw = await dao.getSyntaxTreesForVerse('GEN', 1, 1);
      expect(raw, isNotNull);
      expect(RealSyntaxNode.parseTreesJson(raw!), isNotEmpty);

      // A whole book must resolve: the block covers every verse in it.
      for (final verse in [1, 2, 3, 31]) {
        expect(
          await dao.getSyntaxTreesForVerse('JHN', 1, verse),
          isNotNull,
          reason: 'JHN 1:$verse should carry a tree',
        );
      }

      // Reading another book evicts the previous block without breaking.
      expect(await dao.getSyntaxTreesForVerse('REV', 22, 21), isNotNull);
      expect(await dao.getSyntaxTreesForVerse('GEN', 1, 1), isNotNull);
    });
  });
}
