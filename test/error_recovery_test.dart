import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/providers/books_provider.dart';
import 'package:original_bible/features/reading/book_picker_screen.dart';
import 'package:original_bible/features/explain/explain_diagnostics_screen.dart';
import 'package:original_bible/features/explain/explain_health.dart';
import 'package:original_bible/features/explain/explain_provider.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/features/search/search_screen.dart';

Widget _app(Widget child, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  testWidgets(
    'leaving search disposes the query and cancels pending input safely',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      container.read(searchQueryProvider.notifier).state = 'w';
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const Scaffold(body: Text('Closed'))),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(container.read(searchQueryProvider), isEmpty);
    },
  );

  testWidgets(
    'failed books hide internal errors and retry loads the book list',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booksProvider.overrideWith((ref) async {
              if (attempts++ == 0)
                throw StateError('/private/database/path/secret.db');
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
            }),
          ],
          child: _app(const BookPickerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('/private/'), findsNothing);
      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('Genesis'), findsWidgets);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'diagnostics use Portuguese statuses and wrap at large text sizes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            explainHealthProvider.overrideWith(
              (ref) async => [
                ModelHealth(
                  modelId: 'test/model',
                  total: 10,
                  ok: 6,
                  suspect: 3,
                  errors: 1,
                  medianMs: 1000,
                  lastFailureNote: 'HTTP 429',
                  lastUsed: DateTime(2026),
                ),
              ],
            ),
          ],
          child: _app(
            const ExplainDiagnosticsScreen(),
            language: 'pt',
            scale: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pouco confiável. Considere trocar.'), findsOneWidget);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Unreliable — consider switching'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
