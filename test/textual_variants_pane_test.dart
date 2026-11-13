/// The reader's "other editions" pane.
///
/// It is a text comparison, not an apparatus: it names the edition, shows what
/// each reads, and stays on one line until asked. The tests pin the three
/// things that would make it wrong — appearing where the editions agree,
/// claiming a reading that is an omission, and opening itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/textual_variant.dart';
import 'package:original_bible/features/reading/widgets/textual_variants_pane.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';

class _VariantsDao extends BibleDAO {
  _VariantsDao(this.variants);

  final List<TextualVariant> variants;

  @override
  Future<List<TextualVariant>> getTextualVariants({
    required String bookId,
    required int chapter,
    required int verse,
  }) async => variants;
}

Widget _pane(List<TextualVariant> variants) {
  return ProviderScope(
    overrides: [bibleDaoProvider.overrideWithValue(_VariantsDao(variants))],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TextualVariantsPane(
          bookId: 'MAT',
          chapter: 6,
          verse: 13,
          fontSize: 18,
        ),
      ),
    ),
  );
}

const _doxology = TextualVariant(
  id: 1,
  bookId: 'MAT',
  chapter: 6,
  verse: 13,
  position: 0,
  edition: 'RP2018',
  baseReading: '',
  otherReading: 'ὅτι σοῦ ἐστιν ἡ βασιλεία καὶ ἡ δύναμις καὶ ἡ δόξα',
);

const _substitution = TextualVariant(
  id: 2,
  bookId: 'LUK',
  chapter: 2,
  verse: 14,
  position: 0,
  edition: 'RP2018',
  baseReading: 'εὐδοκίας',
  otherReading: 'εὐδοκία',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a verse where the editions agree shows nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_pane(const []));
    await tester.pumpAndSettle();

    expect(find.text('Other editions'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pane names the edition and stays closed', (tester) async {
    await tester.pumpWidget(_pane(const [_substitution]));
    await tester.pumpAndSettle();

    expect(find.text('Other editions'), findsOneWidget);
    expect(find.text('RP2018'), findsOneWidget);
    // Closed: the readings are not on screen yet.
    expect(find.text('εὐδοκίας'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping opens both readings, labelled', (tester) async {
    await tester.pumpWidget(_pane(const [_substitution]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other editions'));
    await tester.pumpAndSettle();

    expect(find.text('SBLGNT'), findsOneWidget);
    expect(find.text('εὐδοκίας'), findsOneWidget);
    expect(find.text('Robinson–Pierpont (Byzantine, 2018)'), findsOneWidget);
    expect(find.text('εὐδοκία'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an addition names the missing base reading as absent', (
    tester,
  ) async {
    await tester.pumpWidget(_pane(const [_doxology]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other editions'));
    await tester.pumpAndSettle();

    // The base text has nothing here; saying so beats an empty line.
    expect(find.text('not present'), findsOneWidget);
    expect(
      find.text('ὅτι σοῦ ἐστιν ἡ βασιλεία καὶ ἡ δύναμις καὶ ἡ δόξα'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
