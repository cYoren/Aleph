/// The depth panes of the definition sheet, rendered.
///
/// Senses, the Hebrew root and the attested forms are three separate reads, and
/// each has to land in the sheet without pushing the rest off screen or
/// overflowing. Numbers and headings are asserted because they are what a
/// learner actually reads.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/lexicon_root.dart';
import 'package:original_bible/data/models/lexicon_sense.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:original_bible/shared/widgets/lexicon_depth_sections.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyDao extends BibleDAO {
  @override
  Future<List<LexiconSense>> getSensesForStrongs(
    String key, {
    int limit = 120,
  }) async => const [];

  @override
  Future<LexiconRoot?> getRootForStrongs(String key) async => null;

  @override
  Future<List<Map<String, dynamic>>> getAttestedForms(
    String lemma, {
    int limit = 400,
  }) async => const [];
}

class _FakeBibleDao extends BibleDAO {
  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async {
    return LexiconEntry(
      strongsId: 'H1288',
      lemma: 'בָּרַךְ',
      transliteration: 'bāraḵ',
      pronunciation: 'baw-rak',
      gloss: 'to bless',
      definition: 'To bless, to kneel; Strong\'s H1288.',
      language: 'heb',
      extendedDefinition: 'BDB entry text for ברך.',
      extendedSource: 'BDB',
    );
  }

  @override
  Future<List<LexiconSense>> getSensesForStrongs(
    String key, {
    int limit = 120,
  }) async {
    if (key != 'H1288') return const [];
    return const [
      LexiconSense(
        strongsId: 'H1288',
        source: 'BDB',
        level: 0,
        number: '',
        heading: 'Qal',
        summary: 'Qal',
      ),
      LexiconSense(
        strongsId: 'H1288',
        source: 'BDB',
        level: 1,
        number: '1',
        heading: 'kneel down',
        summary: 'kneel down',
      ),
      LexiconSense(
        strongsId: 'H1288',
        source: 'BDB',
        level: 1,
        number: '2',
        heading: 'bless',
        summary: 'bless, adore with bended knees',
      ),
      LexiconSense(
        strongsId: 'H1288',
        source: 'BDB',
        level: 0,
        number: '',
        heading: 'Pi',
        summary: 'Pi',
      ),
    ];
  }

  @override
  Future<LexiconRoot?> getRootForStrongs(String key) async {
    if (key != 'H1288') return null;
    return const LexiconRoot(
      strongsId: 'H1288',
      root: 'בָּרַךְ',
      gloss: 'kneel',
      twot: '285',
    );
  }

  @override
  Future<List<RootMember>> getRootMembers(String twot) async => const [
    RootMember(strongsId: 'H1288', lemma: 'בָּרַךְ', gloss: 'to bless', count: 330),
    RootMember(
      strongsId: 'H1293',
      lemma: 'בְּרָכָה',
      gloss: 'a blessing',
      count: 71,
    ),
  ];

  @override
  Future<List<Map<String, dynamic>>> getAttestedForms(
    String lemma, {
    int limit = 400,
  }) async {
    return const [
      {'form': 'בָּרוּךְ', 'morph': 'Vqsmsa', 'count': 60},
      {'form': 'בֵּרַךְ', 'morph': 'Vpp3ms', 'count': 30},
      {'form': 'יְבָרֵךְ', 'morph': 'Vpi3ms', 'count': 20},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getStrongsUsageFrequencies(
    String strongs,
  ) async => const [];

  @override
  Future<int> countOccurrencesForLexiconKey(String key) async => 330;

  @override
  Future<List<Book>> getBooks() async => const [];
}

Widget _panes() {
  return ProviderScope(
    overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SensesSection(lexiconKey: 'H1288'),
              RootSection(lexiconKey: 'H1288', isHebrew: true),
              ParticipantSection(
                subjectText: 'אֱלֹהִים',
                subjectStrongs: 'H430',
                referentText: null,
                referentStrongs: null,
                isHebrew: true,
              ),
              AttestedFormsSection(lemma: 'בָּרַךְ', isHebrew: true),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders numbered senses instead of one paragraph', (
    tester,
  ) async {
    await tester.pumpWidget(_panes());
    await tester.pumpAndSettle();

    expect(find.text('SENSES'), findsOneWidget);
    expect(find.text('Qal'), findsWidgets);
    expect(find.text('kneel down'), findsOneWidget);
    expect(find.text('bless'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the root and the way into its word family', (
    tester,
  ) async {
    await tester.pumpWidget(_panes());
    await tester.pumpAndSettle();

    expect(find.text('ROOT'), findsOneWidget);
    expect(find.text('2 words'), findsOneWidget);
    expect(find.text('kneel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups attested forms by binyan', (tester) async {
    await tester.pumpWidget(_panes());
    await tester.pumpAndSettle();

    expect(find.text('FORMS IN THE TEXT'), findsOneWidget);
    expect(find.text('Qal'), findsWidgets);
    expect(find.text('בָּרוּךְ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('names the subject of the verb', (tester) async {
    await tester.pumpWidget(_panes());
    await tester.pumpAndSettle();

    expect(find.text('SUBJECT'), findsOneWidget);
    expect(find.text('אֱלֹהִים'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing when the database has no depth layers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleDaoProvider.overrideWithValue(_EmptyDao())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: const [
                SensesSection(lexiconKey: 'H9999'),
                RootSection(lexiconKey: 'H9999', isHebrew: true),
                AttestedFormsSection(lemma: 'nothing', isHebrew: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // An older database must show the flattened entry, not empty boxes.
    expect(find.text('SENSES'), findsNothing);
    expect(find.text('FORMS IN THE TEXT'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
