/// The on-ramp, screen by screen.
///
/// This is the only path in the app written for someone who has never seen a
/// Hebrew letter, so the guarantees are: the three letters appear, the example
/// word appears with its sound and meaning, every word of the first verse is
/// glossed, and the reader leaves with real review cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/database/daos/srs_dao.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/features/alphabet/alphabet_provider.dart';
import 'package:original_bible/features/onboarding/first_steps_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBibleDao extends BibleDAO {
  @override
  Future<List<Word>> getWordsForVerse(String verseId) async {
    return [
      Word(
        id: 1,
        verseId: 'GEN.1.1',
        position: 1,
        displayText: 'בְּרֵאשִׁית',
        lemma: 'רֵאשִׁית',
        strongs: 'H7225',
        morphCode: 'HNcfsa',
        language: 'heb',
      ),
      Word(
        id: 2,
        verseId: 'GEN.1.1',
        position: 2,
        displayText: 'בָּרָא',
        lemma: 'בָּרָא',
        strongs: 'H1254',
        morphCode: 'Vqp3ms',
        language: 'heb',
      ),
      Word(
        id: 3,
        verseId: 'GEN.1.1',
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
  Future<Map<String, LexiconEntry>> getLexiconEntriesForStrongs(
    List<String> strongsNumbers,
  ) async {
    return {
      'H7225': LexiconEntry(
        strongsId: 'H7225',
        lemma: 'רֵאשִׁית',
        gloss: 'beginning',
        language: 'heb',
      ),
      'H1254': LexiconEntry(
        strongsId: 'H1254',
        lemma: 'בָּרָא',
        gloss: 'create',
        language: 'heb',
      ),
      'H430': LexiconEntry(
        strongsId: 'H430',
        lemma: 'אֱלֹהִים',
        gloss: 'God',
        language: 'heb',
      ),
    };
  }

  @override
  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    return {'GEN.1.1': 'In the beginning God created the heavens and the earth.'};
  }
}

class _FakeSrsDao extends SrsDao {}

/// The alphabet asset, as the letters step needs it: the first three letters
/// with their sounds and one example word each.
AlphabetReference _reference() {
  const hebrew = AlphabetChart(
    fontFamily: 'EzraSIL',
    isRtl: true,
    letters: [
      AlphabetLetter(
        id: 'alef',
        glyph: 'א',
        name: 'Alef',
        transliteration: 'ʾ',
        strongs: 'H430',
        lemma: 'אֱלֹהִים',
        lemmaTransliteration: 'ʾĕlōhiym',
        gloss: 'God',
      ),
      AlphabetLetter(
        id: 'bet',
        glyph: 'ב',
        name: 'Bet',
        transliteration: 'b / v',
      ),
      AlphabetLetter(
        id: 'gimel',
        glyph: 'ג',
        name: 'Gimel',
        transliteration: 'g',
      ),
    ],
    vowels: [],
  );
  const greek = AlphabetChart(
    fontFamily: 'Gentium',
    isRtl: false,
    letters: [
      AlphabetLetter(
        id: 'alpha',
        glyph: 'Α α',
        name: 'Alpha',
        transliteration: 'a',
        strongs: 'G26',
        lemma: 'ἀγάπη',
        lemmaTransliteration: 'agapē',
        gloss: 'love',
      ),
    ],
    vowels: [],
  );
  return AlphabetReference(
    hebrew: hebrew,
    greek: greek,
    hints: const {'alef': 'a soft catch in the throat; silent after a vowel'},
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      bibleDaoProvider.overrideWithValue(_FakeBibleDao()),
      srsDaoProvider.overrideWithValue(_FakeSrsDao()),
      // Real asset I/O does not settle inside a widget test, so the reference
      // is supplied rather than loaded.
      alphabetReferenceProvider.overrideWith((ref) async => _reference()),
      alphabetExampleGlossesProvider.overrideWith(
        (ref) async => {'H430': 'God'},
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts with three letters and their sounds', (tester) async {
    await tester.pumpWidget(_wrap(const FirstStepsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Three letters'), findsOneWidget);
    expect(find.text('א'), findsWidgets);
    expect(find.textContaining('Alef'), findsOneWidget);
  });

  testWidgets('the second step shows a real word with its meaning', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const FirstStepsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('One word'), findsOneWidget);
    expect(find.text('אֱלֹהִים'), findsOneWidget);
    expect(find.text('God'), findsOneWidget);
  });

  testWidgets('the verse step glosses every word and shows the translation', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const FirstStepsScreen()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('One verse'), findsOneWidget);
    expect(find.text('בְּרֵאשִׁית'), findsOneWidget);
    expect(find.text('beginning'), findsOneWidget);
    expect(find.text('create'), findsOneWidget);
    expect(
      find.text('In the beginning God created the heavens and the earth.'),
      findsOneWidget,
    );
  });

  testWidgets('the last step offers the five words as review cards', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const FirstStepsScreen()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Five words'), findsOneWidget);
    expect(find.text('Review these five'), findsOneWidget);
  });
}
