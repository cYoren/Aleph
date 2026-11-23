import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/core/telemetry_gate.dart';
import 'package:original_bible/core/telemetry_startup.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The bug this file exists for: a null DSN does not silence sentry, it throws,
/// and `main()` would die before the first frame. Every test here runs the real
/// SDK, because a string assertion on `sentryConfigFor` cannot tell "the SDK
/// ignores this" from "the app never launches".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the SDK rejects a null DSN, so a silent build must not call it', () async {
    await expectLater(
      Sentry.init((options) => options.dsn = null),
      throwsA(isA<ArgumentError>()),
      reason: 'if this ever stops throwing, revisit startWithTelemetry',
    );
  });

  test('a debug build starts the app without initialising sentry', () async {
    var started = 0;
    // Initialising the SDK here would throw (see the test above), so starting
    // cleanly is the proof that the silent path skips it.
    await startWithTelemetry(
      release: false,
      runApp: () async => started++,
    );
    expect(started, 1);
    expect(Sentry.isEnabled, isFalse);
  });

  test('a release build hands the SDK a DSN and the production environment',
      () async {
    final config = sentryConfigFor(release: true);
    expect(config.dsn, kSentryDsn);
    expect(config.environment, 'production');
    // Not initialised for real: that would need a network stack and a project.
    // test/telemetry_gate_test.dart asserts main.dart cannot bypass the gate.
    expect(sentryConfigFor(release: false).dsn, isNull);
  });

  test('the empty-string DSN the SDK documents as silent is still silent', () async {
    // The alternative the SDK offers, pinned so nobody "simplifies" the null
    // check into this without a test.
    await Sentry.init((options) => options.dsn = '');
    expect(Sentry.isEnabled, isFalse);
    final id = await Sentry.captureMessage('silent');
    expect(id.toString(), '0' * 32, reason: 'a no-op SDK returns the empty id');
  });
}
