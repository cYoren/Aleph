import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:original_bible/shared/widgets/verse_with_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longBdbText =
    'plural in number: rulers, judges, either as divine representatives at '
    'sacred places or as reflecting divine majesty and power; divine ones, '
    'superhuman beings including God and angels; angels; gods; specifically '
    'used of the one true God with singular verbs and adjectives, the '
    'supreme God of Israel, maker of heaven and earth, covenant God of the '
    'patriarchs and of the people, judge of all the earth.';

class _FakeBibleDao extends BibleDAO {
  @override
  Future<List<Word>> getWordsForVerse(String verseId) async {
    return [
      Word(
        id: 3,
        verseId: verseId,
        position: 3,
        displayText: 'אֱלֹהִים',
        lemma: 'אֱלֹהִים',
        strongs: 'H430',
        morphCode: 'HNcmpa',
        language: 'heb',
      ),
    ];
  }

  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async {
    if (key != 'H430') return null;
    return LexiconEntry(
      strongsId: 'H430',
      lemma: 'אֱלֹהִים',
      transliteration: 'elohim',
      pronunciation: 'el-o-heem',
      gloss: 'God',
      definition: 'Gods in the ordinary sense; the supreme God.',
      language: 'heb',
      extendedDefinition: _longBdbText,
      extendedSource: 'BDB',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getStrongsUsageFrequencies(
    String strongs,
  ) async {
    return [
      {'book_id': 'GEN', 'count': 219},
    ];
  }

  @override
  Future<List<Book>> getBooks() async {
    return [
      Book(
        id: 1,
        abbreviation: 'GEN',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapterCount: 50,
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap a word -> definition sheet with lexicon and BDB entry', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final verse = Verse(
      id: 'GEN.1.1',
      bookId: 'GEN',
      chapter: 1,
      verseNumber: 1,
      textContent: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VerseWithWords(verse: verse, isOT: true, fontSize: 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The word renders and is tappable.
    expect(find.text('אֱלֹהִים'), findsOneWidget);
    await tester.tap(find.text('אֱלֹהִים'));
    await tester.pumpAndSettle();

    // The sheet opened on the lemma section.
    expect(find.text('LEMMA (DICTIONARY FORM)'), findsOneWidget);

    // Expand the draggable sheet so lower sections are hit-testable.
    await tester.drag(
      find.text('LEMMA (DICTIONARY FORM)'),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    // Scroll the sheet's list to reach each section (content below the
    // fold is lazily built).
    final sheetList = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('God'), 80, scrollable: sheetList);
    expect(find.text('God'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Gods in the ordinary sense; the supreme God.'),
      80,
      scrollable: sheetList,
    );

    // Scholarly BDB entry, collapsed with a Show more toggle.
    await tester.scrollUntilVisible(
      find.text('BDB (BROWN–DRIVER–BRIGGS)'),
      80,
      scrollable: sheetList,
    );
    await tester.scrollUntilVisible(
      find.text('Show more'),
      80,
      scrollable: sheetList,
    );
    expect(find.textContaining('covenant God'), findsNothing);
    await tester.ensureVisible(find.text('Show more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('covenant God'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);

    // Concordance entry point is offered.
    await tester.scrollUntilVisible(
      find.text('See all occurrences'),
      80,
      scrollable: sheetList,
    );
    expect(find.text('See all occurrences'), findsOneWidget);
  });
}
