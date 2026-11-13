/// The root screen: every word on a root, and every verse those words appear in.
///
/// This is the feature a concordance cannot do — בָּרַךְ (bless) and בְּרָכָה
/// (blessing) are separate Strong's numbers, so the point of the screen is that
/// both appear at once, with their counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_root.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/features/word_study/root_study_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBibleDao extends BibleDAO {
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
  Future<int> countOccurrencesForRoot(String twot) async => 390;

  @override
  Future<List<Verse>> getOccurrencesForRoot(
    String twot, {
    int limit = 300,
  }) async => [
    Verse(
      id: 'GEN.12.2',
      bookId: 'GEN',
      chapter: 12,
      verseNumber: 2,
      textContent: 'וֶהְיֵה בְּרָכָה',
    ),
  ];

  @override
  Future<List<Book>> getBooks() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists every word on the root with its count', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RootStudyScreen(root: 'בָּרַךְ', gloss: 'kneel', twot: '285'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('בָּרַךְ'), findsWidgets);
    expect(find.text('בְּרָכָה'), findsOneWidget);
    expect(find.text('330'), findsOneWidget);
    expect(find.text('71'), findsOneWidget);
  });

  testWidgets('counts the verses of the whole root family', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RootStudyScreen(root: 'בָּרַךְ', gloss: 'kneel', twot: '285'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('390'), findsOneWidget);
    expect(find.text('וֶהְיֵה בְּרָכָה'), findsOneWidget);
  });
}
