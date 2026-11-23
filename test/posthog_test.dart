import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:original_bible/core/posthog.dart';
import 'package:original_bible/core/telemetry_gate.dart';
import 'package:original_bible/core/usage_events.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one gate that matters: nothing leaves the device unless the reader
/// turned the switch on, and when it does leave, it carries no text.
void main() {
  // A test process is a debug build, and a debug build is silenced in production
  // code (see core/telemetry_gate.dart). These tests are about what happens
  // *after* that gate, so they open it explicitly and reset it afterwards.
  setUp(() => debugUsageCountsOverride = true);
  tearDown(() => debugUsageCountsOverride = null);

  group('postHogEnabled', () {
    test('is off with an empty project key', () {
      expect(postHogEnabled(projectKey: ''), isFalse);
      expect(postHogEnabled(projectKey: '   '), isFalse);
    });

    test('is on with the shipped key', () {
      expect(postHogEnabled(), isTrue);
      expect(postHogEnabled(projectKey: 'phc_test'), isTrue);
    });
  });

  group('sanitizeProperties', () {
    test('keeps small enums, numbers and booleans', () {
      final clean = sanitizeProperties({
        'book': 'JHN',
        'testament': 'nt',
        'layer': 'senses',
        'duration_ms': 42,
        'success': true,
      });
      expect(clean, {
        'book': 'JHN',
        'testament': 'nt',
        'layer': 'senses',
        'duration_ms': 42,
        'success': true,
      });
    });

    test('drops anything that could be a person, a query or a note', () {
      final clean = sanitizeProperties({
        'email': 'reader@example.com',
        'user_name': 'Someone',
        'apiToken': 'abc',
        'password': 'x',
        'secret': 'x',
        'message': 'x',
        'text': 'In the beginning',
        'search_query': 'bereshit',
        'prompt': 'x',
        'content': 'a note about this verse',
        'transcript': 'x',
        'note': 'my highlight',
      });
      expect(clean, isEmpty);
    });

    test('drops long free strings and nested values', () {
      final clean = sanitizeProperties({
        'title': 'Genesis 1', // survives: not blocked, short
        'gloss': 'a' * 200, // too long to be an enum
        'words': ['one', 'two'], // not a scalar
      });
      expect(clean, {'title': 'Genesis 1'});
    });
  });

  group('buildPostHogEvent', () {
    test('carries the app slug, platform, version and no person profile', () {
      final event = buildPostHogEvent(
        event: 'chapter_read',
        distinctId: 'install-1',
        timestamp: DateTime.utc(2026, 11, 22, 10),
        properties: {'book': 'GEN', 'testament': 'ot', 'note': 'no'},
        locale: 'pt',
        platform: 'ios',
      );

      expect(event['event'], 'chapter_read');
      expect(event['distinct_id'], 'install-1');
      expect(event['timestamp'], '2026-11-22T10:00:00.000Z');
      final props = event['properties'] as Map<String, Object?>;
      expect(props['app'], 'aleph');
      expect(props['platform'], 'ios');
      expect(props['app_version'], kAnalyticsAppVersion);
      expect(props['locale'], 'pt');
      expect(props[r'$process_person_profile'], isFalse);
      expect(props['book'], 'GEN');
      expect(props.containsKey('note'), isFalse);
    });

    test('every event has a fresh id', () {
      final first = buildPostHogEvent(
        event: 'app_opened',
        distinctId: 'install-1',
        timestamp: DateTime.utc(2026),
      );
      final second = buildPostHogEvent(
        event: 'app_opened',
        distinctId: 'install-1',
        timestamp: DateTime.utc(2026),
      );
      expect(first['uuid'], isNot(second['uuid']));
      expect((first['uuid'] as String).length, 32);
    });
  });

  group('batch body', () {
    test('is the shape PostHog /batch/ expects', () {
      final event = buildPostHogEvent(
        event: 'first_value',
        distinctId: 'install-1',
        timestamp: DateTime.utc(2026),
      );
      final body = buildPostHogBody([event], projectKey: 'phc_test');
      expect(body['api_key'], 'phc_test');
      expect((body['batch'] as List), hasLength(1));
      // It has to survive JSON encoding as-is; no odd types.
      expect(() => jsonEncode(body), returnsNormally);
    });
  });

  group('the gate', () {
    test('off when the reader opted out', () {
      expect(postHogAllowed(optedIn: false), isFalse);
      expect(postHogAllowed(optedIn: false, isWeb: false), isFalse);
    });

    test('off when no key ships, even if the reader opted in', () {
      expect(postHogAllowed(optedIn: true, projectKey: ''), isFalse);
    });

    test('off on web, which has no Settings switch', () {
      expect(postHogAllowed(optedIn: true, isWeb: true), isFalse);
    });

    test('on only when opted in, keyed and native', () {
      expect(postHogAllowed(optedIn: true, isWeb: false), isTrue);
    });

    test('a refused event never reaches the network', () async {
      final client = _CountingClient();
      final sent = await sendToPostHog(
        optedIn: false,
        event: 'app_opened',
        client: client,
      );
      expect(sent, isFalse);
      expect(client.calls, 0);
    });

    test('an empty project key never reaches the network', () async {
      final client = _CountingClient();
      final sent = await sendToPostHog(
        optedIn: true,
        event: 'app_opened',
        projectKey: '',
        client: client,
      );
      expect(sent, isFalse);
      expect(client.calls, 0);
    });
  });

  group('off switches', () {
    test('the shipped key is a public ingestion key, never a personal one', () {
      expect(kPostHogProjectKey.startsWith('phc_'), isTrue);
      expect(kPostHogProjectKey.startsWith('phx_'), isFalse);
    });
  });

  group('the wrapper', () {
    test('record() returns without waiting for delivery', () async {
      // Opted in, so both senders would fire. One of them is pointed at a client
      // that never answers: if `record` awaited delivery, this test would hang
      // until the 5 s timeout instead of returning.
      SharedPreferences.setMockInitialValues({
        'usageSharingEnabled': true,
        'installDay': '2026-11-01',
        'appLanguage': 'en',
      });
      debugPostHogClient = _NeverAnsweringClient();
      addTearDown(() => debugPostHogClient = null);

      final watch = Stopwatch()..start();
      await UsageEvents.record(UsageEvent.supportOpened);
      watch.stop();

      expect(watch.elapsedMilliseconds, lessThan(1000));
    });

    test('record() sends nothing when the reader opted out', () async {
      SharedPreferences.setMockInitialValues({
        'usageSharingEnabled': false,
        'installDay': '2026-11-01',
      });
      final client = _CountingClient();
      debugPostHogClient = client;
      addTearDown(() => debugPostHogClient = null);

      await UsageEvents.record(UsageEvent.chapterRead);
      // Give a wrongly dispatched send a chance to reach the client.
      await Future<void>.delayed(Duration.zero);

      expect(client.calls, 0);
    });

    test('the Settings switch is live in every build now that PostHog is in',
        () {
      expect(UsageEvents.isConfigured, isTrue);
    });

    test('a chapter read before consent does not use up first_value', () async {
      SharedPreferences.setMockInitialValues({
        'usageSharingEnabled': false,
        'installDay': '2026-11-01',
        'appLanguage': 'en',
      });
      final client = _RecordingClient();
      debugPostHogClient = client;
      addTearDown(() => debugPostHogClient = null);

      // Reads before opting in: nothing is sent, and the funnel event is kept.
      await UsageEvents.recordChapterRead(
        bookId: 'GEN',
        isOldTestament: true,
      );
      await _settle(client);
      expect(client.events, isEmpty);

      // Then they opt in in Settings, and read again.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('usageSharingEnabled', true);
      await UsageEvents.recordChapterRead(
        bookId: 'JHN',
        isOldTestament: false,
      );
      await _settle(client, atLeast: 2);
      expect(client.events, ['chapter_read', 'first_value']);

      // A third chapter is just another chapter.
      await UsageEvents.recordChapterRead(
        bookId: 'PSA',
        isOldTestament: true,
      );
      await _settle(client, atLeast: 3);
      expect(client.events, ['chapter_read', 'first_value', 'chapter_read']);
    });

    test('first_value fires once for a reader who opted in first', () async {
      SharedPreferences.setMockInitialValues({
        'usageSharingEnabled': true,
        'installDay': '2026-11-01',
        'appLanguage': 'en',
      });
      final client = _RecordingClient();
      debugPostHogClient = client;
      addTearDown(() => debugPostHogClient = null);

      for (final book in ['GEN', 'EXO', 'LEV']) {
        await UsageEvents.recordChapterRead(
          bookId: book,
          isOldTestament: true,
        );
        await _settle(client, atLeast: client.events.length + 1);
        await Future<void>.delayed(Duration.zero);
      }

      expect(client.events.where((e) => e == 'first_value'), hasLength(1));
      expect(client.events.where((e) => e == 'chapter_read'), hasLength(3));
    });
  });

  group('constants', () {
    test('kAnalyticsAppVersion matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
      expect(kAnalyticsAppVersion, match!.group(1));
    });

    test('the app slug is the one the project expects', () {
      expect(kAnalyticsApp, 'aleph');
    });
  });
}

/// Records whether anything was posted, so a refused event can be proven silent.
class _CountingClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    return http.StreamedResponse(const Stream<List<int>>.empty(), 200);
  }
}

/// Keeps the event names it was asked to deliver, so a test can see what would
/// have left the device.
class _RecordingClient extends http.BaseClient {
  final List<String> events = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonDecode(await request.finalize().bytesToString());
    for (final entry in (body['batch'] as List)) {
      events.add((entry as Map)['event'] as String);
    }
    return http.StreamedResponse(const Stream<List<int>>.empty(), 200);
  }
}

/// Delivery is dispatched, not awaited, so give it a few turns to arrive.
Future<void> _settle(_RecordingClient client, {int atLeast = 1}) async {
  for (var i = 0; i < 100 && client.events.length < atLeast; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A client that never answers, so a caller waiting on delivery would hang.
class _NeverAnsweringClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future;
}
