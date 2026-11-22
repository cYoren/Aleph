import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:original_bible/core/posthog.dart';

/// The one gate that matters: nothing leaves the device unless the reader
/// turned the switch on, and when it does leave, it carries no text.
void main() {
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
