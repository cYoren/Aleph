/// Starts the app, with crash reporting only when this build may report.
///
/// This exists because of a trap: handing `SentryFlutter.init` a null DSN does
/// **not** silence the SDK, it throws `ArgumentError('DSN is required.')`
/// (sentry 10.3.0, `lib/src/sentry.dart` and `hub.dart`), so `main()` would die
/// before the first frame and the app would never launch. A build that must stay
/// silent therefore has to skip the initialisation entirely, not pass it null.
///
/// See `core/telemetry_gate.dart` for which builds report.
library;

import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry_gate.dart';

/// Runs [runApp], wrapped in Sentry when [release] says this build may report.
///
/// Separate from `main()` so the silent path can be tested without a simulator
/// and without the production project.
Future<void> startWithTelemetry({
  required bool release,
  required Future<void> Function() runApp,
}) async {
  final config = sentryConfigFor(release: release);
  final dsn = config.dsn;
  if (dsn == null) {
    await runApp();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = config.environment;
      // 10% of sessions: enough to see a slow screen without paying for all of them.
      options.tracesSampleRate = 0.1;
      // Never attach IPs or account emails on its own.
      options.sendDefaultPii = false;
    },
    appRunner: runApp,
  );
}
