/// One place that decides whether this build may report anything at all.
///
/// Two things leave the app by themselves: crashes and hangs (Sentry) and the
/// opt-in usage counts (the proxy and PostHog). Both used to be wired into
/// every build, so a simulator launch, a local device run or a test that boots
/// the app wrote into the same production projects the store builds use. Sentry
/// ALEPH-3 and ALEPH-4 were exactly that: one debug simulator pass whose "app
/// hangs" were the bundled database unpacking under the JIT and the smoke's own
/// terminate calls.
///
/// A released app is always a release build, so gating on [kReleaseMode] leaves
/// every shipped behaviour untouched while making a development build silent.
library;

import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;

/// Public by design: it ships inside the app and cannot read anything.
const String kSentryDsn =
    'https://e39562958e8e46bfef713a8c56fd91b5@o4510739590742016.ingest.us.sentry.io/4512405014183936';

/// The DSN a build reports to, or null when it must stay silent.
///
/// A null DSN makes the SDK a no-op, so no event, breadcrumb or transaction is
/// ever sent. Expressed as a function of `release` rather than read from
/// [kReleaseMode] directly so both answers can be tested.
String? sentryDsnFor({required bool release}) => release ? kSentryDsn : null;

/// Labels the environment on every event, so a release report is never confused
/// with a development one.
String sentryEnvironmentFor({required bool release}) =>
    release ? 'production' : 'debug';

/// Whether the opt-in usage counts may be dispatched at all. Consent is a
/// second, independent gate inside `UsageEvents.record`.
bool usageCountsFor({required bool release}) => release;

/// Test seam. A test process is a debug build, so the tests that prove what
/// `record()` does when the reader has opted in must be able to open the gate;
/// they set this and reset it in `tearDown`. Nothing in `lib/` may set it.
@visibleForTesting
bool? debugUsageCountsOverride;

/// What this build should do, resolved once at startup.
class TelemetryGate {
  const TelemetryGate._();

  static String? get sentryDsn => sentryDsnFor(release: kReleaseMode);

  static String get sentryEnvironment =>
      sentryEnvironmentFor(release: kReleaseMode);

  static bool get usageCounts =>
      debugUsageCountsOverride ?? usageCountsFor(release: kReleaseMode);
}
