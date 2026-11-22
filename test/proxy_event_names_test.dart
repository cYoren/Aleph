import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/core/usage_events.dart';

/// The app's wire names and the proxy's allowlist are two hand-kept lists in two
/// languages, so they drift silently: the worker answers 400 for an unknown name
/// and the app swallows the response, which loses a count with no trace. This
/// reads `proxy/worker.js` and makes the drift a test failure instead.
void main() {
  test('the proxy accepts every event the app sends', () {
    final worker = File('proxy/worker.js').readAsStringSync();
    final block = RegExp(
      r'const EVENT_NAMES = new Set\(\[([\s\S]*?)\]\);',
    ).firstMatch(worker);
    expect(block, isNotNull, reason: 'EVENT_NAMES moved or was renamed');
    final accepted = RegExp(r"'([a-z_]+)'")
        .allMatches(block!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();

    final expected = UsageEvent.values.map((e) => e.wireName).toSet();
    expect(
      accepted,
      expected,
      reason: 'proxy/worker.js EVENT_NAMES and UsageEvent.wireName drifted',
    );
  });

  test('wire names and PostHog names are unique', () {
    final wire = UsageEvent.values.map((e) => e.wireName).toList();
    final postHog = UsageEvent.values.map((e) => e.postHogName).toList();
    expect(wire.toSet(), hasLength(wire.length));
    expect(postHog.toSet(), hasLength(postHog.length));
  });
}
