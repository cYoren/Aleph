import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/translation.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/main.dart';
import 'package:original_bible/providers/database_provider.dart';

class _FakeDao extends BibleDAO {
  @override
  Future<List<Book>> getBooks() async => [
    Book(id: 1, abbreviation: 'GEN', name: 'Genesis', testament: 'OT', order: 1, chapterCount: 50),
  ];
  @override
  Future<List<Verse>> getVersesForChapter(String b, int c) async => [];
  @override
  Future<Map<String, String>> getTranslationVersesForChapter(String b, int c, String t) async => {};
  @override
  Future<List<Word>> getWordsForVerse(String v) async => [];
  @override
  Future<LexiconEntry?> getLexiconEntry(String k) async => null;
  @override
  Future<Map<String, LexiconEntry>> getLexiconEntriesForStrongs(List<String> i) async => {};
  @override
  Future<List<Translation>> getTranslations() async => [
    Translation(id: 'KJV', name: 'KJV', language: 'en', abbreviation: 'KJV'),
  ];
}

/// The alphabet guide is the entry point for a reader who knows neither
/// script, reached from a tile on the home screen. This walks that whole path —
/// boot, home, tap, letters on screen — because a guide that renders perfectly
/// but cannot be reached is indistinguishable from one that is broken.
void main() {
  testWidgets('the alphabet guide is reachable from home and shows both scripts',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
      'appLanguage': 'en',
      'translation': 'KJV',
      // An installed reader who is past the on-ramp: without these the startup
      // gate routes to /start by design.
      'firstRunVerseAt': 1,
      'firstRunReviewAt': 1,
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [bibleDaoProvider.overrideWithValue(_FakeDao())],
      child: const OriginalBibleApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('The alphabet'), findsOneWidget);

    await tester.tap(find.text('The alphabet'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Alef'), findsOneWidget);
    // Greek has to be visibly on offer, not buried: the New Testament reader
    // needs to see it exists the moment the guide opens.
    expect(find.text('Greek'), findsOneWidget);
  });
}
