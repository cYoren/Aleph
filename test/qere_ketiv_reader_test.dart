/// The qere/ketiv pair in the reader.
///
/// The flowing text follows the reading tradition in almost every case, so the
/// thing a reader cannot otherwise see is what the scroll actually writes. The
/// qere display mode puts that beside the word, and only in that mode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/shared/widgets/tappable_word.dart';
import 'package:shared_preferences/shared_preferences.dart';

Word _word({
  String displayText = 'הַיְצֵ֣א',
  String? qereText = 'הַיְצֵ֣א',
  String? ketivText = 'הוצא',
  String language = 'heb',
}) {
  return Word(
    id: 1,
    verseId: '1',
    position: 1,
    displayText: displayText,
    lemma: 'יָצָא',
    strongs: 'H3318',
    morphCode: 'HVhv2ms',
    language: language,
    qereText: qereText,
    ketivText: ketivText,
  );
}

Widget _reader(Word word) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: TappableWord(word: word, isOT: true, fontSize: 24),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('qere mode shows the written form beside the reading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'hebrewTextDisplay': 'qere'});
    await tester.pumpWidget(_reader(_word()));
    await tester.pumpAndSettle();

    expect(find.text('הַיְצֵ֣א'), findsOneWidget);
    // The siglum is the one printed editions use for ketiv.
    expect(find.text('כ הוצא'), findsOneWidget);
  });

  testWidgets('the other modes stay quiet', (tester) async {
    SharedPreferences.setMockInitialValues({'hebrewTextDisplay': 'full'});
    await tester.pumpWidget(_reader(_word()));
    await tester.pumpAndSettle();

    expect(find.text('הַיְצֵ֣א'), findsOneWidget);
    expect(find.textContaining('הוצא'), findsNothing);
  });

  testWidgets('a word with no variant shows no second line', (tester) async {
    SharedPreferences.setMockInitialValues({'hebrewTextDisplay': 'qere'});
    await tester.pumpWidget(
      _reader(_word(qereText: null, ketivText: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('הַיְצֵ֣א'), findsOneWidget);
    expect(find.textContaining('כ '), findsNothing);
  });

  testWidgets('when the text carries the written form, the reading is shown', (
    tester,
  ) async {
    // 1,075 of the 1,244 pairs have the reading in the flowing text; the rest
    // do not, and the app must not assume which.
    SharedPreferences.setMockInitialValues({'hebrewTextDisplay': 'qere'});
    await tester.pumpWidget(_reader(_word(displayText: 'הוצא')));
    await tester.pumpAndSettle();

    expect(find.text('ק הַיְצֵ֣א'), findsOneWidget);
  });
}
