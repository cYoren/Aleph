import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:original_bible/features/explain/explain_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'test-key';

ExplainService _service(
  Future<http.Response> Function(http.Request) handler, {
  String? apiKey = _key,
}) {
  return ExplainService(
    client: MockClient(handler),
    apiKeyOverride: apiKey,
  );
}

http.Response _completion(String content) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': content},
            'finish_reason': 'stop',
          }
        ],
      }),
    ),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Future<String> _explain(ExplainService service) {
  return service.explain(
    reference: 'Genesis 1:1',
    originalText: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים',
    translationText: 'In the beginning God created',
    isHebrew: true,
    languageName: 'English',
  );
}

void main() {
  // The service records every  call's outcome for the diagnostics screen, and that
  // write goes through SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('configuration', () {
    test('reports unconfigured when no key was compiled in', () {
      final service = _service((_) async => _completion('x'), apiKey: '');
      expect(service.isConfigured, isFalse);
    });

    test('refuses to call the network without a key', () async {
      var called = false;
      final service = _service(
        (_) async {
          called = true;
          return _completion('x');
        },
        apiKey: '',
      );

      await expectLater(
        _explain(service),
        throwsA(
          isA<ExplainException>().having(
            (e) => e.failure,
            'failure',
            ExplainFailure.notConfigured,
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('request shape', () {
    test('excludes reasoning and allows a large token budget', () async {
      late Map<String, dynamic> sent;
      final service = _service((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _completion('ok');
      });

      await _explain(service);

      // Both of these were found by testing the live model. Without
      // reasoning.exclude the model returns its chain of thought as the
      // answer; with a small budget it is truncated mid-sentence before it
      // writes anything useful.
      expect(sent['reasoning'], {'exclude': true});
      expect(sent['max_tokens'], greaterThanOrEqualTo(2000));
      expect(sent['model'], kExplainModel);
    });

    test('sends the passage and asks for the reader\'s language', () async {
      late Map<String, dynamic> sent;
      final service = _service((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _completion('ok');
      });

      await service.explain(
        reference: 'John 1:1',
        originalText: 'Ἐν ἀρχῇ ἦν ὁ λόγος',
        translationText: 'In the beginning was the Word',
        isHebrew: false,
        languageName: 'Portuguese',
      );

      final messages = sent['messages'] as List;
      final system = messages.first['content'] as String;
      final user = messages.last['content'] as String;

      expect(system, contains('Portuguese'));
      expect(user, contains('John 1:1'));
      expect(user, contains('Ἐν ἀρχῇ'));
      expect(user, contains('Greek'));
    });

    test('authenticates with the supplied key', () async {
      late String auth;
      final service = _service((request) async {
        auth = request.headers['Authorization'] ?? '';
        return _completion('ok');
      });

      await _explain(service);
      expect(auth, 'Bearer $_key');
    });
  });

  group('proxy', () {
    test('goes to the proxy without sending any key', () async {
      late http.Request sent;
      final service = ExplainService(
        client: MockClient((request) async {
          sent = request;
          return _completion('ok');
        }),
        apiKeyOverride: '',
        proxyUrlOverride: 'https://proxy.example/explain',
      );

      expect(service.isConfigured, isTrue);
      await _explain(service);
      expect(sent.url.toString(), 'https://proxy.example/explain');
      expect(sent.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('responses', () {
    test('returns the explanation text', () async {
      final service = _service((_) async => _completion('  An explanation.  '));
      expect(await _explain(service), 'An explanation.');
    });

    test('decodes Hebrew and Greek in the answer as UTF-8', () async {
      // http defaults to latin-1 when the charset is unstated, which would
      // mangle the original-language words the model quotes back.
      final service = _service(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'The word בָּרָא and ὁ λόγος.'}
                }
              ],
            }),
          ),
          200,
        ),
      );

      final text = await _explain(service);
      expect(text, contains('בָּרָא'));
      expect(text, contains('ὁ λόγος'));
    });
  });

  group('failures', () {
    test('maps 401 to a bad key', () async {
      final service = _service(
        (_) async => http.Response('{"error":{"code":401}}', 401),
      );
      await expectLater(
        _explain(service),
        throwsA(
          isA<ExplainException>()
              .having((e) => e.failure, 'failure', ExplainFailure.badKey),
        ),
      );
    });

    test('maps 429 to rate limited, which a free tier will hit', () async {
      final service = _service((_) async => http.Response('slow down', 429));
      await expectLater(
        _explain(service),
        throwsA(
          isA<ExplainException>()
              .having((e) => e.failure, 'failure', ExplainFailure.rateLimited),
        ),
      );
    });

    test('maps a network error to offline', () async {
      final service = _service((_) async => throw const SocketExceptionStub());
      await expectLater(
        _explain(service),
        throwsA(
          isA<ExplainException>()
              .having((e) => e.failure, 'failure', ExplainFailure.offline),
        ),
      );
    });

    test('treats an empty completion as a failure, not as an answer', () async {
      final service = _service((_) async => _completion('   '));
      await expectLater(
        _explain(service),
        throwsA(
          isA<ExplainException>()
              .having((e) => e.failure, 'failure', ExplainFailure.failed),
        ),
      );
    });

    test('handles a malformed body', () async {
      final service = _service((_) async => http.Response('not json', 200));
      await expectLater(
        _explain(service),
        throwsA(isA<ExplainException>()),
      );
    });
  });
}

/// Stands in for a socket failure without importing dart:io into the test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
