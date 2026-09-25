/// Opt-in AI explanation of a passage, via OpenRouter.
///
/// This is the **only** part of the app that touches the network. Everything
/// else — text, lexicons, morphology, syntax trees, cross-references, audio —
/// works with no connection at all, and that stays true for any reader who
/// leaves this feature switched off (it is off by default).
///
/// The API key is supplied at build time and is never committed:
///
/// ```bash
/// flutter build ios --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
/// ```
///
/// With no key defined the feature reports itself unavailable and the UI hides
/// it entirely, so a source build with no key is a working offline app rather
/// than an app with a broken button.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'explain_health.dart';
import 'explain_model.dart';

/// Default model id, kept for tests and for callers that do not choose a
/// tier. The real choice lives in `explain_model.dart`.
const String kExplainModel = 'nvidia/nemotron-3.5-lightning:free';

const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

/// Compile-time key. Empty unless supplied with `--dart-define`.
///
/// Prefer [kAiProxyUrl] for release builds: a compiled-in key can be pulled
/// out of the binary.
const String kCompiledApiKey = String.fromEnvironment('OPENROUTER_API_KEY');

/// The Aleph proxy (proxy/worker.js), which holds the key server-side. When
/// set, requests go there with no Authorization header.
const String kAiProxyUrl = String.fromEnvironment('ALEPH_AI_PROXY');

/// Why an explanation could not be produced.
enum ExplainFailure {
  /// The build carries no API key, so the feature is not available at all.
  notConfigured,

  /// No network, or the request timed out.
  offline,

  /// The key was rejected (401/403).
  badKey,

  /// Rate limited — likely, since the model runs on a free tier.
  rateLimited,

  /// Anything else: a 5xx, a malformed body, an empty completion.
  failed,
}

class ExplainException implements Exception {
  const ExplainException(this.failure, [this.detail]);

  final ExplainFailure failure;
  final String? detail;

  @override
  String toString() => 'ExplainException($failure, $detail)';
}

/// Requests short, beginner-facing explanations of a passage.
class ExplainService {
  ExplainService({
    http.Client? client,
    String? apiKeyOverride,
    String? proxyUrlOverride,
    ExplainHealthStore? health,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKeyOverride ?? kCompiledApiKey,
        _proxyUrl = proxyUrlOverride ?? kAiProxyUrl,
        _health = health ?? ExplainHealthStore();

  final http.Client _client;
  final String _apiKey;
  final String _proxyUrl;
  final ExplainHealthStore _health;

  /// False when neither a proxy nor a key was compiled in; the UI hides the
  /// feature entirely rather than offering a button that cannot work.
  bool get isConfigured => _proxyUrl.isNotEmpty || _apiKey.isNotEmpty;

  /// Explains [reference] to a learner.
  ///
  /// [originalText] is the Hebrew or Greek; [translationText] the reader's
  /// chosen translation. [languageName] is the language to answer in, so a
  /// Portuguese reader gets a Portuguese explanation.
  Future<String> explain({
    required String reference,
    required String originalText,
    required String translationText,
    required bool isHebrew,
    required String languageName,
    ExplainModelConfig config = kFreeModel,
  }) async {
    if (!isConfigured) {
      throw const ExplainException(ExplainFailure.notConfigured);
    }

    final language = isHebrew ? 'Hebrew' : 'Greek';
    final stopwatch = Stopwatch()..start();

    final body = jsonEncode({
      'model': config.modelId,
      'max_tokens': config.maxTokens,
      'temperature': 0.3,
      // Without this the model prints its chain of thought as the answer,
      // so the reader sees "Here's a thinking process: 1. Analyze User
      // Request..." instead of an explanation.
      if (kExplainReasoningExcluded)
        'reasoning': {
          'exclude': true,
          if (config.reasoningEffort != null) 'effort': config.reasoningEffort,
        },
      'messages': [
        {
          'role': 'system',
          'content': buildExplainSystemPrompt(languageName: languageName),
        },
        {
          'role': 'user',
          'content': 'Reference: $reference\n'
              'Original ($language): $originalText\n'
              'Translation: $translationText\n\n'
              'Explain this passage.',
        },
      ],
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_proxyUrl.isNotEmpty ? _proxyUrl : _endpoint),
            headers: {
              if (_proxyUrl.isEmpty) 'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              // OpenRouter uses these for attribution on its dashboards.
              'HTTP-Referer': 'https://github.com/cYoren/Aleph',
              'X-Title': 'Aleph',
            },
            body: utf8.encode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      if (kDebugMode) debugPrint('ExplainService network failure: $e');
      await _recordError(config, stopwatch, 'network/timeout');
      throw const ExplainException(ExplainFailure.offline);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _recordError(config, stopwatch, 'auth ${response.statusCode}');
      throw ExplainException(ExplainFailure.badKey, response.body);
    }
    if (response.statusCode == 429) {
      await _recordError(config, stopwatch, 'rate limited');
      throw ExplainException(ExplainFailure.rateLimited, response.body);
    }
    if (response.statusCode != 200) {
      await _recordError(config, stopwatch, 'HTTP ${response.statusCode}');
      throw ExplainException(
        ExplainFailure.failed,
        'HTTP ${response.statusCode}',
      );
    }

    final String text;
    try {
      text = _extractContent(response.bodyBytes);
    } on ExplainException catch (e) {
      await _recordError(config, stopwatch, e.detail ?? 'bad body');
      rethrow;
    }

    // A 200 with a useless answer is the failure mode that would otherwise go
    // unnoticed — the model degrades, nothing throws, and the reader just gets
    // something worse. Record it so the diagnostics screen can show it.
    stopwatch.stop();
    final problem = ExplainQualityCheck.problemWith(text);
    await _health.record(
      ExplainSample(
        modelId: config.modelId,
        outcome: problem == null ? ExplainOutcome.ok : ExplainOutcome.suspect,
        milliseconds: stopwatch.elapsedMilliseconds,
        at: DateTime.now(),
        note: problem,
      ),
    );

    return text;
  }

  Future<void> _recordError(
    ExplainModelConfig config,
    Stopwatch stopwatch,
    String note,
  ) async {
    stopwatch.stop();
    await _health.record(
      ExplainSample(
        modelId: config.modelId,
        outcome: ExplainOutcome.error,
        milliseconds: stopwatch.elapsedMilliseconds,
        at: DateTime.now(),
        note: note,
      ),
    );
  }

  /// Pulls the explanation out of an OpenRouter completion.
  ///
  /// Decoded as UTF-8 explicitly: the answers quote Hebrew and Greek, which
  /// `http`'s default latin-1 fallback would mangle.
  String _extractContent(List<int> bodyBytes) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw ExplainException(ExplainFailure.failed, 'malformed response: $e');
    }

    if (decoded['error'] != null) {
      throw ExplainException(ExplainFailure.failed, '${decoded['error']}');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ExplainException(ExplainFailure.failed, 'no choices');
    }

    final message = (choices.first as Map<String, dynamic>)['message'];
    final content = (message as Map<String, dynamic>?)?['content'];
    final text = content?.toString().trim() ?? '';

    if (text.isEmpty) {
      throw const ExplainException(ExplainFailure.failed, 'empty completion');
    }
    return text;
  }

  void dispose() => _client.close();
}
