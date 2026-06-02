import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/features/reading/reading_provider.dart';
import 'package:original_bible/features/settings/settings_provider.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedBibleDao extends BibleDAO {
  _DelayedBibleDao(this._chapterDelays);

  final Map<int, Duration> _chapterDelays;

  Future<void> _waitForChapter(int chapter) async {
    final delay = _chapterDelays[chapter];
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<List<Verse>> getVersesForChapter(String bookId, int chapter) async {
    await _waitForChapter(chapter);
    return [
      Verse(
        id: '$bookId.$chapter.1',
        bookId: bookId,
        chapter: chapter,
        verseNumber: 1,
        textContent: 'original-$chapter',
      ),
    ];
  }

  @override
  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    await _waitForChapter(chapter);
    return {'$bookId.$chapter.1': 'translation-$chapter'};
  }
}

Future<void> _waitForLoadedSettings(ProviderContainer container) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(settingsProvider).isLoaded) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Settings were not loaded in time.');
}

Future<void> _waitForInitialReadingLoad(ProviderContainer container) async {
  for (var i = 0; i < 150; i++) {
    final state = container.read(readingProvider);
    if (!state.isLoading && state.verses.isNotEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Initial reading state did not finish loading in time.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('latest chapter load wins when requests overlap', () async {
    SharedPreferences.setMockInitialValues({
      'translation': 'KJV',
      'appLanguage': 'en',
      'lastReadBook': 'EXO',
      'lastReadChapter': 1,
      'hasCompletedOnboarding': true,
      'hasManuallySelectedTranslation': false,
    });

    final container = ProviderContainer(
      overrides: [
        bibleDaoProvider.overrideWithValue(
          _DelayedBibleDao({
            1: const Duration(milliseconds: 120),
            2: const Duration(milliseconds: 5),
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForLoadedSettings(container);

    // Trigger notifier creation and wait for the startup load to settle.
    container.read(readingProvider.notifier);
    await _waitForInitialReadingLoad(container);

    final notifier = container.read(readingProvider.notifier);

    unawaited(notifier.loadChapter('GEN', 1));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await notifier.loadChapter('GEN', 2);
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final state = container.read(readingProvider);
    expect(state.chapter, equals(2));
    expect(state.verses.first.chapter, equals(2));
    expect(state.getTranslation('GEN.2.1'), equals('translation-2'));
  });
}
