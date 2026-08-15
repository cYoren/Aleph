import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/explain/explain_health.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExplainSample _sample(
  ExplainOutcome outcome, {
  String model = 'test/model',
  int ms = 5000,
  String? note,
}) {
  return ExplainSample(
    modelId: model,
    outcome: outcome,
    milliseconds: ms,
    at: DateTime(2026, 8, 15),
    note: note,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('quality checks', () {
    test('accepts an ordinary explanation', () {
      const good =
          'The verb bara means "created", and in the Hebrew Bible it takes '
          'only God as its subject, which marks this as a distinct kind of act.';
      expect(ExplainQualityCheck.problemWith(good), isNull);
    });

    test('catches leaked chain of thought', () {
      // The exact shape seen from a reasoning model when reasoning exclusion
      // is not set.
      const leaked =
          "Here's a thinking process: 1. Analyze User Request. 2. Deconstruct "
          'the Hebrew and translation into parts for the explanation.';
      expect(
        ExplainQualityCheck.problemWith(leaked),
        'model leaked its reasoning',
      );
    });

    test('catches an outline where prose was asked for', () {
      const outline =
          '1. The word bara means created. 2. Elohim is plural in form. '
          '3. The particle et marks the object of the verb here.';
      expect(
        ExplainQualityCheck.problemWith(outline),
        'answer is an outline, not prose',
      );
    });

    test('catches truncation', () {
      // What a too-small max_tokens produces: cut off mid-clause.
      const cut =
          'The word bara means "created", and in the Hebrew Bible this verb is '
          'used only with God as its subject, which';
      expect(
        ExplainQualityCheck.problemWith(cut),
        'answer appears truncated',
      );
    });

    test('catches empty and too-short answers', () {
      expect(ExplainQualityCheck.problemWith('   '), 'empty answer');
      expect(ExplainQualityCheck.problemWith('Yes.'), 'answer too short');
    });
  });

  group('health rollup', () {
    test('summarises success rate and median latency', () async {
      final store = ExplainHealthStore();
      for (final ms in [4000, 6000, 5000, 5000, 5000]) {
        await store.record(_sample(ExplainOutcome.ok, ms: ms));
      }

      final health = (await store.health()).single;
      expect(health.total, 5);
      expect(health.ok, 5);
      expect(health.successRate, 1.0);
      expect(health.medianMs, 5000);
      expect(health.verdict, 'Healthy');
      expect(health.needsAttention, isFalse);
    });

    test('withholds a verdict until there are enough calls to judge', () async {
      final store = ExplainHealthStore();
      await store.record(_sample(ExplainOutcome.ok));
      await store.record(_sample(ExplainOutcome.ok));

      final health = (await store.health()).single;
      expect(health.hasEnoughEvidence, isFalse);
      expect(health.verdict, 'Too early to tell');
    });

    test('separates models', () async {
      final store = ExplainHealthStore();
      await store.record(_sample(ExplainOutcome.ok, model: 'a'));
      await store.record(_sample(ExplainOutcome.error, model: 'b'));

      final health = await store.health();
      expect(health.map((h) => h.modelId).toSet(), {'a', 'b'});
    });

    test('flags a model that mostly fails', () async {
      final store = ExplainHealthStore();
      for (var i = 0; i < 4; i++) {
        await store.record(_sample(ExplainOutcome.error, note: 'HTTP 500'));
      }
      await store.record(_sample(ExplainOutcome.ok));

      final health = (await store.health()).single;
      expect(health.needsAttention, isTrue);
      expect(health.verdict, contains('switch'));
      expect(health.lastFailureNote, 'HTTP 500');
    });

    test('flags a model that got very slow', () async {
      final store = ExplainHealthStore();
      for (var i = 0; i < 6; i++) {
        await store.record(_sample(ExplainOutcome.ok, ms: 40000));
      }

      final health = (await store.health()).single;
      expect(health.needsAttention, isTrue);
      expect(health.verdict, contains('slow'));
    });

    test('stays quiet until there is enough evidence', () async {
      // One bad call on a train is not a degraded model. An alert that fires
      // on noise gets ignored exactly when it matters.
      final store = ExplainHealthStore();
      await store.record(_sample(ExplainOutcome.error));
      await store.record(_sample(ExplainOutcome.error));

      final health = (await store.health()).single;
      expect(health.total, 2);
      expect(health.needsAttention, isFalse);
    });

    test('counts poor answers separately from errors', () async {
      final store = ExplainHealthStore();
      for (var i = 0; i < 5; i++) {
        await store.record(_sample(ExplainOutcome.ok));
      }
      await store.record(
        _sample(ExplainOutcome.suspect, note: 'model leaked its reasoning'),
      );

      final health = (await store.health()).single;
      expect(health.suspect, 1);
      expect(health.errors, 0);
      expect(health.verdict, contains('poor answers'));
    });

    test('will not advise switching on too little evidence', () async {
      // The verdict and the warning badge must agree: no "switch model" text
      // on a sample size that does not trigger needsAttention.
      final store = ExplainHealthStore();
      await store.record(_sample(ExplainOutcome.error));
      await store.record(_sample(ExplainOutcome.error));

      final health = (await store.health()).single;
      expect(health.needsAttention, isFalse);
      expect(health.verdict, isNot(contains('switch')));
    });

    test('keeps only a rolling window', () async {
      final store = ExplainHealthStore(maxSamples: 5);
      for (var i = 0; i < 12; i++) {
        await store.record(_sample(ExplainOutcome.ok));
      }
      expect((await store.samples()).length, 5);
    });

    test('clears', () async {
      final store = ExplainHealthStore();
      await store.record(_sample(ExplainOutcome.ok));
      await store.clear();
      expect(await store.health(), isEmpty);
    });
  });
}
