import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/features/audio/recitation_provider.dart';
import 'package:original_bible/features/audio/recitation_service.dart';
import 'package:original_bible/features/audio/widgets/recitation_bar.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';

/// Stands in for the platform speech engine. [speak] blocks on a completer
/// the test controls, so the notifier can be driven to the "playing" state
/// and held there for assertions without a real voice or a race.
class _FakeRecitationService extends RecitationService {
  VoiceAvailability availability = VoiceAvailability.ready;
  final List<String> spoken = [];
  Completer<void>? _gate;

  @override
  Future<VoiceAvailability> availabilityFor(String languageCode) async =>
      availability;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
  }) async {}

  @override
  Future<bool> speak(String text) async {
    spoken.add(text);
    _gate = Completer<void>();
    await _gate!.future;
    return true;
  }

  @override
  Future<void> stop() async {
    if (_gate != null && !_gate!.isCompleted) {
      _gate!.complete();
    }
  }
}

Verse _verse(int number, String text) => Verse(
      id: 'GEN.1.$number',
      bookId: 'GEN',
      chapter: 1,
      verseNumber: number,
      textContent: text,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows nothing while idle', (tester) async {
    final container = ProviderContainer(
      overrides: [
        recitationServiceProvider.overrideWithValue(
          _FakeRecitationService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecitationBar(reference: 'Genesis 1', onStop: () {}),
          ),
        ),
      ),
    );

    // The Scaffold itself contributes a Material; RecitationBar must not add
    // one of its own while idle (it renders SizedBox.shrink).
    expect(
      find.descendant(
        of: find.byType(RecitationBar),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'shows the reference and current verse while playing, and stops on tap',
    (tester) async {
      final service = _FakeRecitationService();
      final container = ProviderContainer(
        overrides: [recitationServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RecitationBar(
                reference: 'Genesis 1',
                onStop: () =>
                    container.read(recitationProvider.notifier).stop(),
              ),
            ),
          ),
        ),
      );

      // Fire and forget: speak() blocks on the fake's gate, so awaiting this
      // directly would hang the test.
      unawaited(
        container.read(recitationProvider.notifier).startChapter(
              bookId: 'GEN',
              chapter: 1,
              verses: [_verse(1, 'א'), _verse(2, 'ב')],
              isHebrew: true,
            ),
      );

      // Pump past the awaits (stop -> preparing -> availabilityFor ->
      // configure -> speak) up to the point speak() blocks.
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(find.text('Genesis 1'), findsOneWidget);
      expect(find.text('Verse 1'), findsOneWidget);
      expect(service.spoken, hasLength(1));

      // The rate selector cycles: default is 0.5, next is 0.6.
      expect(find.text('0.5x'), findsOneWidget);
      await tester.tap(find.text('0.5x'));
      await tester.pump();
      expect(find.text('0.6x'), findsOneWidget);

      // Stopping releases the gate and returns the bar to idle.
      await tester.tap(find.byIcon(Icons.stop_rounded));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(find.text('Verse 1'), findsNothing);
      expect(container.read(recitationProvider).status,
          RecitationStatus.idle);
    },
  );

  testWidgets('explains a missing voice instead of failing silently', (
    tester,
  ) async {
    final service = _FakeRecitationService()
      ..availability = VoiceAvailability.voiceMissing;
    final container = ProviderContainer(
      overrides: [recitationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecitationBar(
              reference: 'Genesis 1',
              onStop: () =>
                  container.read(recitationProvider.notifier).stop(),
            ),
          ),
        ),
      ),
    );

    unawaited(
      container.read(recitationProvider.notifier).startChapter(
            bookId: 'GEN',
            chapter: 1,
            verses: [_verse(1, 'א')],
            isHebrew: true,
          ),
    );
    await tester.pumpAndSettle();

    // No voice, so nothing was ever handed to the engine, and the reader is
    // told why rather than seeing silent, unexplained failure.
    expect(service.spoken, isEmpty);
    expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
    expect(
      find.textContaining('needs a Hebrew or Greek speech voice'),
      findsOneWidget,
    );

    // The notice says installing is quick and one-off rather than describing a
    // route through the system settings — on Android the button beside it does
    // the navigating. These tests run on the host, where there is no installer
    // to offer, so only the wording is asserted here.
    expect(find.textContaining('system speech settings'), findsNothing);
  });
}
