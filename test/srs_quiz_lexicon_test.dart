import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/features/reading/widgets/srs_micro_quiz_sheet.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two Hebrew words with different lexicon entries. The object marker's gloss
/// is the bare "(et)" that used to stick to every later review card.
class _FakeBibleDao extends BibleDAO {
  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async {
    switch (key) {
      case 'H0853':
        return LexiconEntry(
          strongsId: 'H0853',
          lemma: 'אֵת',
          transliteration: 'ʾeṯ-',
          pronunciation: 'ʾeṯ-',
          gloss: '(et)',
          language: 'heb',
        );
      case 'H4480':
        return LexiconEntry(
          strongsId: 'H4480',
          lemma: 'מִן',
          transliteration: 'min',
          pronunciation: 'min',
          gloss: 'from (a place)',
          language: 'heb',
        );
    }
    return null;
  }
}

/// Deck review cards are built with the sentinel id -1; keep it so the test
/// reproduces the shared-identity bug rather than avoiding it.
Word _deckWord(String strongs, String lemma) => Word(
  id: -1,
  verseId: '',
  position: 0,
  displayText: lemma,
  lemma: lemma,
  strongs: strongs,
  language: 'heb',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('each deck review shows its own lexicon entry', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => SrsMicroQuizSheet.show(
                      context,
                      originalWord: _deckWord('H0853', 'אֵת'),
                      translatedWord: 'object marker',
                      isOT: true,
                    ),
                    child: const Text('open object marker'),
                  ),
                  TextButton(
                    onPressed: () => SrsMicroQuizSheet.show(
                      context,
                      originalWord: _deckWord('H4480', 'מִן'),
                      translatedWord: 'from',
                      isOT: true,
                    ),
                    child: const Text('open from'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // First card: the object marker's own gloss is shown under the translation.
    await tester.tap(find.text('open object marker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal Answer'));
    await tester.pumpAndSettle();
    expect(find.text('(et)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Second card: must show its own entry, not the first card's "(et)".
    await tester.tap(find.text('open from'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal Answer'));
    await tester.pumpAndSettle();
    expect(find.text('from (a place)'), findsOneWidget);
    expect(find.text('(et)'), findsNothing);
  });
}
