/// The clock behind "your first verse in N minutes".
///
/// The claim only means something if the measurement is honest: it starts at the
/// first launch of the app, not when the reader happens to reach the reading
/// screen, and it never rewrites the first time once recorded.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/onboarding/first_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launch = DateTime(2026, 11, 13, 8, 0);

  group('FirstRunState', () {
    test('nothing is complete before the first verse', () {
      const state = FirstRunState();
      expect(state.isComplete, isFalse);
      expect(state.minutesToFirstVerse, isNull);
    });

    test('minutes run from first launch to the first verse', () {
      final state = FirstRunState(
        launchedAt: launch,
        verseAt: launch.add(const Duration(minutes: 7, seconds: 20)),
      );
      expect(state.minutesToFirstVerse, 7);
      expect(state.hasReadFirstVerse, isTrue);
      expect(state.isComplete, isFalse);
    });

    test('under a minute reports zero, not a fake one', () {
      final state = FirstRunState(
        launchedAt: launch,
        verseAt: launch.add(const Duration(seconds: 40)),
      );
      expect(state.minutesToFirstVerse, 0);
    });

    test('the on-ramp is complete only after the first review', () {
      final state = FirstRunState(
        launchedAt: launch,
        lettersAt: launch.add(const Duration(minutes: 1)),
        verseAt: launch.add(const Duration(minutes: 4)),
        reviewAt: launch.add(const Duration(minutes: 9)),
      );
      expect(state.isComplete, isTrue);
      expect(state.minutesToFirstVerse, 4);
    });
  });

  group('FirstRunNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('the first verse is stamped once and stays put', () async {
      final notifier = FirstRunNotifier();
      await notifier.touchLaunch();
      final first = notifier.state.launchedAt;
      expect(first, isNotNull);

      await notifier.completeVerse();
      final verseAt = notifier.state.verseAt;
      expect(verseAt, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await notifier.completeVerse();
      expect(notifier.state.verseAt, verseAt);
      expect(notifier.state.launchedAt, first);
    });

    test('restarting the steps keeps the original launch stamp', () async {
      final notifier = FirstRunNotifier();
      await notifier.touchLaunch();
      final launched = notifier.state.launchedAt;
      await notifier.completeLetters();
      await notifier.completeVerse();
      await notifier.completeReview();
      expect(notifier.state.isComplete, isTrue);

      await notifier.restart();

      expect(notifier.state.isComplete, isFalse);
      expect(notifier.state.lettersAt, isNull);
      expect(notifier.state.launchedAt, launched);
    });
  });
}
