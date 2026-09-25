// A test harness that lives outside test/ so the suite does not run it.
// ignore_for_file: invalid_use_of_visible_for_testing_member

// Renders store screenshot raws from the real app with the real database,
// on Linux, no simulator. Not part of the test suite:
//
//   flutter test tool/capture/store_capture_test.dart --update-goldens
//   uv run --no-project --with pillow python3 scripts/compose_store_screenshots.py
//
// Output: tool/capture/raw/<device>/<locale>/NN_name.png at exact store sizes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/app/theme.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/database/daos/srs_dao.dart';
import 'package:original_bible/features/home/home_screen.dart';
import 'package:original_bible/features/names/name_meaning_screen.dart';
import 'package:original_bible/features/paths/book_path_screen.dart';
import 'package:original_bible/features/reading/reading_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/shared/widgets/tappable_word.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _flutterRoot = '/home/gustvmar/.local/share/mise/installs/flutter/3.47.5';

class _Device {
  const _Device(this.name, this.size, this.ratio, this.top, this.bottom);
  final String name;
  final Size size; // physical pixels, the store's exact size
  final double ratio;
  final double top; // safe-area insets in logical pixels
  final double bottom;
}

const _devices = [
  _Device('iphone', Size(1290, 2796), 3, 59, 34),
  _Device('ipad', Size(2064, 2752), 2, 24, 20),
];

const _locales = {'en': 'KJV', 'pt': 'ALMEIDA'};

Future<void> _font(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

/// A believable learner: the 30 most common words of Ruth mastered, the next
/// 15 in progress.
Future<void> _seedLearner() async {
  final counts = await BibleDAO().getLexiconKeyCountsInBook('RUT');
  final grammar = (await BibleDAO().getGrammarLexiconKeys()).toSet();
  final keys = counts.keys.where((k) => !grammar.contains(k)).toList();
  final srs = SrsDao();
  for (final key in keys.take(30)) {
    for (var i = 0; i < 4; i++) {
      await srs.recordReview(key, isCorrect: true);
    }
  }
  for (final key in keys.skip(30).take(15)) {
    await srs.recordReview(key, isCorrect: true);
  }
}

Future<void> _settle(WidgetTester tester, [int rounds = 30]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Fresh learner, and a fresh copy of the bundled Bible (the copy's version
    // stamp does not change between local database rebuilds).
    for (final name in ['user_data.db', 'bible.db', 'bible.db.version']) {
      final file = File('.dart_tool/sqflite_common_ffi/databases/$name');
      if (file.existsSync()) file.deleteSync();
    }
    // Warm the asset cache; loads started inside a test's fake clock can stall.
    await rootBundle.loadString('assets/names.json');
    await rootBundle.loadString('assets/book_names.json');
    await _font('EzraSIL', 'assets/fonts/EzraSIL.ttf');
    await _font('Gentium', 'assets/fonts/Gentium-Regular.ttf');
    await _font('Roboto', '/usr/share/fonts/noto/NotoSans-Regular.ttf');
    await _font(
      'MaterialIcons',
      '$_flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  final shots = <String, (Widget, Future<void> Function(WidgetTester)?)>{
    '01_reading': (const ReadingScreen(), null),
    '02_word': (
      const ReadingScreen(),
      (tester) async {
        await tester.tap(find.byType(TappableWord).at(2));
        await _settle(tester, 15);
      },
    ),
    '03_path': (const BookPathScreen(), null),
    '04_name': (
      const NameMeaningScreen(),
      (tester) async {
        await _settle(tester);
        await tester.enterText(find.byType(TextField), 'Daniel');
        await _settle(tester);
        FocusManager.instance.primaryFocus?.unfocus();
        await _settle(tester, 5);
      },
    ),
    '05_home': (const HomeScreen(), null),
  };

  var seeded = false;
  for (final device in _devices) {
    for (final MapEntry(key: locale, value: translation) in _locales.entries) {
      for (final MapEntry(key: name, value: (screen, act)) in shots.entries) {
        testWidgets('${device.name} $locale $name', (tester) async {
          if (!seeded) {
            await tester.runAsync(_seedLearner);
            seeded = true;
          }
          SharedPreferences.setMockInitialValues({
            'hasCompletedOnboarding': true,
            'hasSeenReadingHint': true,
            'appLanguage': locale,
            'translation': translation,
            'showPronunciation': true,
            'activePathBook': 'RUT',
            'streakCount': 12,
            'streakLastDay': DateTime.now().toIso8601String().substring(0, 10),
          });
          tester.view.physicalSize = device.size;
          tester.view.devicePixelRatio = device.ratio;
          tester.view.padding = FakeViewPadding(
            top: device.top * device.ratio,
            bottom: device.bottom * device.ratio,
          );
          tester.view.viewPadding = tester.view.padding;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: Locale(locale),
                theme: AppTheme.light(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: screen,
              ),
            ),
          );
          await _settle(tester);
          if (act != null) await act(tester);

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('raw/${device.name}/$locale/$name.png'),
          );
        });
      }
    }
  }
}
