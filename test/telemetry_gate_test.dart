import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/core/telemetry_gate.dart';

/// Sentry ALEPH-3 and ALEPH-4 were one debug simulator pass: the app reported
/// from the simulator about its own launch and terminate calls, into the same
/// project App Review reads. These tests pin the gate that prevents it, and
/// check the wiring, because the gate is worthless if a build bypasses it.
void main() {
  group('release builds report as before', () {
    test('a release build gets the production DSN', () {
      expect(sentryDsnFor(release: true), kSentryDsn);
      expect(sentryDsnFor(release: true), startsWith('https://'));
    });

    test('a release build is labelled production', () {
      expect(sentryEnvironmentFor(release: true), 'production');
    });

    test('a release build may dispatch the opt-in counts', () {
      expect(usageCountsFor(release: true), isTrue);
    });
  });

  group('development builds are silent', () {
    test('a debug build gets no DSN, which makes the SDK a no-op', () {
      expect(sentryDsnFor(release: false), isNull);
    });

    test('a debug build is labelled debug, never production', () {
      expect(sentryEnvironmentFor(release: false), 'debug');
    });

    test('a debug build dispatches no usage counts', () {
      expect(usageCountsFor(release: false), isFalse);
    });
  });

  group('the test override stays in tests', () {
    tearDown(() => debugUsageCountsOverride = null);

    test('opens and closes the counts gate for a test process', () {
      expect(TelemetryGate.usageCounts, isFalse, reason: 'tests run as debug');
      debugUsageCountsOverride = true;
      expect(TelemetryGate.usageCounts, isTrue);
      debugUsageCountsOverride = false;
      expect(TelemetryGate.usageCounts, isFalse);
    });

    test('nothing under lib/ sets it', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/telemetry_gate.dart')) continue;
        if (entity.readAsStringSync().contains('debugUsageCountsOverride')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'only a test may open the telemetry gate');
    });
  });

  group('the wiring cannot drift from the gate', () {
    final main = File('lib/main.dart');
    final startup = File('lib/core/telemetry_startup.dart');
    final usage = File('lib/core/usage_events.dart');

    test('main.dart starts through startWithTelemetry with the build mode', () {
      final source = main.readAsStringSync();
      expect(source, contains('startWithTelemetry(release: kReleaseMode'));
      expect(
        source.contains('SentryFlutter.init') || RegExp(r'Sentry\.').hasMatch(source),
        isFalse,
        reason: 'main.dart must not touch the SDK directly any more',
      );
    });

    test('the silent path skips init instead of passing a null DSN', () {
      final source = startup.readAsStringSync();
      expect(
        RegExp(r'if\s*\(dsn\s*==\s*null\)').hasMatch(source),
        isTrue,
        reason: 'a null DSN thrown at the SDK kills the launch (ALEPH-3 review)',
      );
      expect(
        RegExp(r'options\.dsn\s*=\s*(?:dsn|config\.dsn)\b').hasMatch(source),
        isTrue,
        reason: 'the DSN handed to the SDK must come from the gate config',
      );
    });

    test('the DSN constant lives in the gate only', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/telemetry_gate.dart')) continue;
        if (entity.readAsStringSync().contains(kSentryDsn)) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'a second copy of the DSN is a second way to bypass the gate',
      );
    });

    test('no file other than the gate names a sentry ingest host', () {
      final offenders = <String>[];
      final ingest = RegExp(r'sentry\.io');
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/telemetry_gate.dart')) continue;
        if (ingest.hasMatch(entity.readAsStringSync())) offenders.add(entity.path);
      }
      expect(offenders, isEmpty, reason: 'a literal ingest URL bypasses the gate');
    });

    test('the usage counts consult the gate before sending', () {
      final source = usage.readAsStringSync();
      expect(
        source,
        contains('TelemetryGate.usageCounts'),
        reason: 'a dev build must not write into the production counts',
      );
    });
  });
}
