import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/shared/widgets/app_scaffold.dart';
import 'package:original_bible/features/onboarding/language_selection_screen.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(820, 1180),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('navigation adapts and routes at $size scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          routes: [
            for (final route in [
              '/',
              '/reading',
              '/bookmarks',
              '/search',
              '/settings',
            ])
              GoRoute(
                path: route,
                builder: (context, state) => AppScaffold(
                  child: Scaffold(body: Text('Destination $route')),
                ),
              ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(NavigationRail),
          size.width >= 720 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(NavigationBar),
          size.width < 720 ? findsOneWidget : findsNothing,
        );
        await tester.ensureVisible(find.text('Settings'));
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('Destination /settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('all languages remain reachable at $size scale $scale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const LanguageSelectionScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Selected language')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('한국어'), 300);
        await tester.ensureVisible(find.text('한국어'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('한국어'));
        await tester.pumpAndSettle();
        expect(find.text('Selected language'), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getString('appLanguage'),
          'ko',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
