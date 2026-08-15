import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/database/daos/srs_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/features/readability/readability_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBibleDao extends BibleDAO {
  @override
  Future<List<Book>> getBooks() async => [
        Book(
          id: 1,
          abbreviation: 'GEN',
          name: 'Genesis',
          testament: 'OT',
          order: 1,
          chapterCount: 50,
        ),
        Book(
          id: 2,
          abbreviation: 'RUT',
          name: 'Ruth',
          testament: 'OT',
          order: 8,
          chapterCount: 4,
        ),
      ];

  @override
  Future<Map<String, int>> getTokenCountsByBook() async => {
        'GEN': 1000,
        'RUT': 100,
      };

  @override
  Future<Map<String, int>> getTokenCountsByBookForKeys(
    List<String> lexiconKeys,
  ) async {
    // Ruth reads as comfortable, Genesis does not.
    if (lexiconKeys.contains('H1')) {
      return {'GEN': 400, 'RUT': 98};
    }
    return {};
  }
}

class _FakeSrsDao extends SrsDao {
  @override
  Future<List<String>> getMasteredLexiconKeys(double threshold) async =>
      ['H1'];
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      bibleDaoProvider.overrideWithValue(_FakeBibleDao()),
      srsDaoProvider.overrideWithValue(_FakeSrsDao()),
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('recommends the book the reader can already read comfortably', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ReadabilityScreen()));
    await tester.pumpAndSettle();

    // Ruth is 98% known -> comfortable; Genesis is 40% -> not. The
    // recommendation card should headline Ruth, not Genesis.
    expect(find.text('You can read this now'), findsOneWidget);
    expect(find.textContaining('Ruth'), findsWidgets);
  });

  testWidgets('lists every book with its coverage percentage', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ReadabilityScreen()));
    await tester.pumpAndSettle();

    expect(find.text('98%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('shows the empty-state card when nothing is mastered yet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleDaoProvider.overrideWithValue(_FakeBibleDao()),
          srsDaoProvider.overrideWithValue(
            _EmptySrsDao(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReadabilityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Start learning words to see this map fill in'),
      findsOneWidget,
    );
    // Coverage is still shown per book (all 0%), just without a headline card.
    expect(find.text('0%'), findsWidgets);
  });
}

class _EmptySrsDao extends SrsDao {
  @override
  Future<List<String>> getMasteredLexiconKeys(double threshold) async => [];
}
