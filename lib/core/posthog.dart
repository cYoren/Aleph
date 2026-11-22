/// PostHog mirror of the consent-gated usage counts in `usage_events.dart`.
///
/// Aleph's own counting (the proxy worker at `/event`) stays where it is. This
/// sends a copy of the same, already anonymised event to PostHog so funnels,
/// retention and later paywall experiments have a home. Plain HTTP POST, no
/// SDK: no native module, no autocapture of inputs, no session replay, no
/// heatmaps, no surveys.
///
/// Nothing here makes its own decisions about consent. Every call arrives from
/// [UsageEvents.record], which has already checked the Settings switch. When
/// the switch is off this file is never called.
///
/// What leaves the device: an event name, a random install id, the interface
/// language, the platform, the app version, and at most a small enum or number
/// (which book, which depth layer, which tip tier). Never a verse reference,
/// never a search term, never a note or a highlight. [sanitizeProperties] drops
/// any property whose key looks like it could carry text or an identifier, so a
/// future call site cannot leak one by accident.
///
/// Off switches, fastest first:
///   1. Reset the project API key in PostHog (Settings > Project > API key):
///      every installed build stops being accepted, no release needed.
///   2. Set [kPostHogProjectKey] to `''` and ship.
///   3. Delete this file and the one call in `usage_events.dart`.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Public by design (write-only ingestion, ships in every build), same as the
/// Sentry DSN in `main.dart`. Never a `phx_` personal key.
const String kPostHogProjectKey =
    'phc_xiF5C5q2NPD6oMh5A2VdUWT7UULDUW8SCGTKZVM7i7mm';

const String kPostHogHost = 'https://us.i.posthog.com';

/// The product slug every event carries, so one project can hold several apps.
const String kAnalyticsApp = 'aleph';

/// Kept in step with `version:` in `pubspec.yaml`; `test/posthog_test.dart`
/// fails the build if the two drift.
const String kAnalyticsAppVersion = '1.0.7';

const String _distinctIdKey = 'analyticsDistinctId';

/// Property keys that could carry a person, a query, or something the reader
/// wrote. Anything matching is dropped before the event leaves the device.
final RegExp _blockedKey = RegExp(
  r'(email|name|token|password|secret|message|text|query|prompt|content|transcript|note)',
  caseSensitive: false,
);

/// True when a project key was compiled into this build.
bool postHogEnabled({String projectKey = kPostHogProjectKey}) =>
    projectKey.trim().isNotEmpty;

/// The single gate. Off when the reader said no, off when no key ships, and off
/// on web builds, where the reader has no Settings switch to turn it back on.
bool postHogAllowed({
  required bool optedIn,
  String projectKey = kPostHogProjectKey,
  bool isWeb = kIsWeb,
}) => optedIn && !isWeb && postHogEnabled(projectKey: projectKey);

/// Enums, numbers and booleans only, and nothing that looks like text or an id.
///
/// Dropping beats redacting: a property that is not on the list simply does not
/// travel, so a careless call site degrades to a missing number instead of a
/// leaked verse.
Map<String, Object?> sanitizeProperties(Map<String, Object?> raw) {
  final clean = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key.isEmpty || _blockedKey.hasMatch(key)) continue;
    final value = entry.value;
    if (value is String || value is num || value is bool) {
      // A long free string is never a small enum; refuse it.
      if (value is String && value.length > 64) continue;
      clean[key] = value;
    }
  }
  return clean;
}

final Random _random = Random.secure();

String _hex(int bytes) {
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// A random id for an event; also used to mint the install id.
@visibleForTesting
String newEventId() => _hex(16);

/// The device id: created once, stored locally, never derived from anything
/// about the reader or the account. There are no accounts here.
Future<String> analyticsDistinctId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_distinctIdKey);
  if (existing != null && existing.isNotEmpty) return existing;
  final id = newEventId();
  await prefs.setString(_distinctIdKey, id);
  return id;
}

String platformName() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

/// One PostHog batch entry.
///
/// Pure, so a test can assert the shape and that `app` is present without
/// touching the network.
Map<String, Object?> buildPostHogEvent({
  required String event,
  required String distinctId,
  required DateTime timestamp,
  Map<String, Object?> properties = const {},
  String locale = 'en',
  String? platform,
}) {
  return {
    'event': event,
    'uuid': newEventId(),
    'distinct_id': distinctId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'properties': <String, Object?>{
      'app': kAnalyticsApp,
      'platform': platform ?? platformName(),
      'app_version': kAnalyticsAppVersion,
      'locale': locale,
      r'$lib': 'aleph-http',
      // Guests only: no person profiles are built from these events.
      r'$process_person_profile': false,
      ...sanitizeProperties(properties),
    },
  };
}

/// The request body PostHog's `/batch/` endpoint expects.
Map<String, Object?> buildPostHogBody(
  List<Map<String, Object?>> events, {
  String projectKey = kPostHogProjectKey,
}) => {'api_key': projectKey, 'batch': events};

/// Test seam: a client that never answers, so a test can prove a caller does
/// not wait for delivery. Always null in a shipped build.
@visibleForTesting
http.Client? debugPostHogClient;

/// Fire and forget. Never throws, never blocks the reader, 5 s at most.
///
/// Returns whether a request was attempted, which is what the tests assert.
Future<bool> sendToPostHog({
  required bool optedIn,
  required String event,
  Map<String, Object?> properties = const {},
  String locale = 'en',
  String? distinctId,
  DateTime? timestamp,
  String projectKey = kPostHogProjectKey,
  http.Client? client,
}) async {
  if (!postHogAllowed(optedIn: optedIn, projectKey: projectKey)) return false;
  try {
    final id = distinctId ?? await analyticsDistinctId();
    final body = buildPostHogBody([
      buildPostHogEvent(
        event: event,
        distinctId: id,
        timestamp: timestamp ?? DateTime.now(),
        properties: properties,
        locale: locale,
      ),
    ], projectKey: projectKey);

    const headers = {'Content-Type': 'application/json'};
    final uri = Uri.parse('$kPostHogHost/batch/');
    final encoded = jsonEncode(body);
    // A test can inject a client; shipping code never does, and never retries.
    final effective = client ?? debugPostHogClient;
    final call = effective == null
        ? http.post(uri, headers: headers, body: encoded)
        : effective.post(uri, headers: headers, body: encoded);
    await call.timeout(const Duration(seconds: 5));
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('PostHog: $e');
    return false;
  }
}
