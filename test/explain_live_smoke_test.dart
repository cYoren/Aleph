/// Live smoke test for the AI passage explanation.
///
/// Skipped unless a real key is supplied, so it is safe in CI and for anyone
/// who clones the repo. To run it against the real endpoint:
///
/// ```bash
/// flutter test test/explain_live_smoke_test.dart \
///   --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
/// ```
///
/// This is the only test that proves the whole path — key wiring, request
/// shape, reasoning exclusion, token budget, UTF-8 decoding — actually works
/// against the live model rather than a mock.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/explain/explain_service.dart';

void main() {
  final hasKey = kCompiledApiKey.isNotEmpty;

  group(
    'live OpenRouter call',
    () {
      test('explains a Hebrew passage', () async {
        final service = ExplainService();
        addTearDown(service.dispose);

        final text = await service.explain(
          reference: 'Genesis 1:1',
          originalText:
              'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ׃',
          translationText:
              'In the beginning God created the heaven and the earth.',
          isHebrew: true,
          languageName: 'English',
        );

        expect(text, isNotEmpty);

        // The model reasons before answering. If reasoning exclusion or the
        // token budget regresses, the answer comes back as visible
        // chain-of-thought instead of an explanation.
        expect(
          text.toLowerCase(),
          isNot(contains('thinking process')),
          reason: 'chain-of-thought leaked into the answer',
        );
        expect(
          text.toLowerCase(),
          isNot(startsWith('1.')),
          reason: 'looks like a reasoning outline, not prose',
        );

        // Long enough to be a real explanation rather than a truncated stub.
        expect(text.length, greaterThan(120));
      }, timeout: const Timeout(Duration(seconds: 90)));

      test('explains a Greek passage', () async {
        final service = ExplainService();
        addTearDown(service.dispose);

        final text = await service.explain(
          reference: 'John 1:1',
          originalText: 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν.',
          translationText: 'In the beginning was the Word.',
          isHebrew: false,
          languageName: 'English',
        );

        expect(text, isNotEmpty);
        expect(text.length, greaterThan(120));
      }, timeout: const Timeout(Duration(seconds: 90)));
    },
    skip: hasKey
        ? false
        : 'no OPENROUTER_API_KEY defined - pass --dart-define to run',
  );
}
