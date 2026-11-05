// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/translation.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/features/home/home_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/app/theme.dart';
import 'package:original_bible/features/onboarding/onboarding_screen.dart';
import 'package:original_bible/features/explain/explain_provider.dart';
import 'package:original_bible/shared/widgets/app_scaffold.dart';

class _FakeBibleDao extends BibleDAO {
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
      Book(
        id: 43,
        abbreviation: 'JHN',
        name: 'John',
        testament: 'NT',
        order: 43,
        chapterCount: 21,
      ),
    ];
  }

  @override
  Future<List<Verse>> getVersesForChapter(String bookId, int chapter) async {
    return [
      Verse(
        id: '$bookId.$chapter.1',
        bookId: bookId,
        chapter: chapter,
        verseNumber: 1,
        textContent: bookId == 'GEN'
            ? 'בְּרֵאשִׁית בָּרָא אֱלֹהִים'
            : 'Ἐν ἀρχῇ ἦν ὁ λόγος',
      ),
    ];
  }

  @override
  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    return {'$bookId.$chapter.1': 'In the beginning'};
  }

  @override
  Future<List<Verse>> search(
    String query, {
    required String translationId,
  }) async => [];

  @override
  Future<List<Word>> getWordsForVerse(String verseId) async => [
    Word.fromMap({
      "id": 1,
      "verse_id": 1,
      "position": 1,
      "word": "בְּ",
      "lemma": "בְּ",
      "morph": "R",
      "strongs": "H0871A",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 2,
      "verse_id": 1,
      "position": 2,
      "word": "רֵאשִׁ֖ית",
      "lemma": "רֵאשִׁית",
      "morph": "Ncfsa",
      "strongs": "H7225",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 3,
      "verse_id": 1,
      "position": 3,
      "word": "בָּרָ֣א",
      "lemma": "בָּרָא",
      "morph": "Vqp3ms",
      "strongs": "H1254",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 4,
      "verse_id": 1,
      "position": 4,
      "word": "אֱלֹהִ֑ים",
      "lemma": "אֱלֹהִים",
      "morph": "Ncmpa",
      "strongs": "H0430",
      "language": "heb",
    }),
  ];

  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async => null;

  @override
  Future<List<Translation>> getTranslations() async {
    return [
      Translation(
        id: 'KJV',
        name: 'King James Version',
        language: 'en',
        abbreviation: 'KJV',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Gentium': 'assets/fonts/Gentium-Regular.ttf',
      'EzraSIL': 'assets/fonts/EzraSIL.ttf',
      'MaterialIcons':
          '/home/gustvmar/.local/share/mise/installs/flutter/latest/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            Future.value(
              ByteData.sublistView(File(entry.value).readAsBytesSync()),
            ),
          ))
          .load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(820, 1180),
    const Size(1440, 900),
  ]) {
    for (final page in [
      'home',
      'onboarding',
      'tradition',
      'ai',
      'dark_home',
      'large_text',
    ]) {
      testWidgets('$page ${size.width}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'hasCompletedOnboarding': true,
        });
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  (page == 'home' || page == 'dark_home')
                  ? const AppScaffold(child: HomeScreen())
                  : const OnboardingScreen(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bibleDaoProvider.overrideWithValue(_FakeBibleDao()),
              explainConfiguredProvider.overrideWithValue(page == 'ai'),
              verseOfDayProvider.overrideWith(
                (ref) async => VerseOfDayData(
                  verse: Verse(
                    id: 'GEN.1.1',
                    bookId: 'GEN',
                    chapter: 1,
                    verseNumber: 1,
                    textContent:
                        'בְּרֵאשִׁ֖ית בָּרָ֣א אֱלֹהִ֑ים אֵ֥ת הַשָּׁמַ֖יִם וְאֵ֥ת הָאָֽרֶץ׃',
                  ),
                  translationText:
                      'In the beginning God created the heavens and the earth.',
                  pronunciation:
                      'bəreshit bara elohim et hashamayim vəet haarets',
                  isOT: true,
                ),
              ),
            ],
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: page == 'dark_home'
                  ? AppTheme.dark('en')
                  : AppTheme.light('en'),
              locale: Locale(page == 'large_text' ? 'de' : 'en'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(page == 'large_text' ? 2 : 1),
                ),
                child: child!,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
        final steps = page == 'ai'
            ? 2
            : (page == 'tradition' || page == 'large_text' ? 1 : 0);
        for (var i = 0; i < steps; i++) {
          await tester.tap(find.text(l10n.next));
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'raw/design/${const String.fromEnvironment('PHASE', defaultValue: 'final')}/${page}_${size.width.toInt()}.png',
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
