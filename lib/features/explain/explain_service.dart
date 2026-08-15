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

/// Model used for explanations.
///
/// This is a *reasoning* model: it spends most of its token budget thinking
/// before answering. Two consequences are baked into the request below and
/// both were found by testing rather than assumption — get either wrong and
/// the feature visibly breaks.
const String kExplainModel = 'nvidia/nemotron-3.5-lightning:free';

const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

/// Compile-time key. Empty unless supplied with `--dart-define`.
const String kCompiledApiKey = String.fromEnvironment('OPENROUTER_API_KEY');

/// Generous, because the model burns roughly 900 tokens on hidden reasoning
/// before it writes a word. At the default of a few hundred it returns a
/// truncated fragment with `finish_reason: length`.
const int _maxTokens = 3000;

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
  ExplainService({http.Client? client, String? apiKeyOverride})
      : _client = client ?? http.Client(),
        _apiKey = apiKeyOverride ?? kCompiledApiKey;

  final http.Client _client;
  final String _apiKey;

  /// False when no key was compiled in; the UI hides the feature entirely
  /// rather than offering a button that cannot work.
  bool get isConfigured => _apiKey.isNotEmpty;

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
  }) async {
    if (!isConfigured) {
      throw const ExplainException(ExplainFailure.notConfigured);
    }

    final language = isHebrew ? 'Hebrew' : 'Greek';

    final body = jsonEncode({
      'model': kExplainModel,
      'max_tokens': _maxTokens,
      'temperature': 0.3,
      // Without this the model prints its chain of thought as the answer,
      // so the reader sees "Here's a thinking process: 1. Analyze User
      // Request..." instead of an explanation.
      'reasoning': {'exclude': true},
      'messages': [
        {
          'role': 'system',
          'content':
              'You explain Bible passages to people learning to read Hebrew '
                  'and Greek in the original. Be clear, warm, and concise. Aim '
                  'at a beginner: do not use grammatical jargon without '
                  'explaining it. Where the original wording carries something '
                  'a translation loses, say so briefly. Do not moralize, '
                  'preach, or give devotional application. Answer in '
                  '$languageName. 150 words maximum. Reply with the '
                  'explanation only.',
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
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              // OpenRouter uses these for attribution on its dashboards.
              'HTTP-Referer': 'https://github.com/cYoren/original-bible-open-source',
              'X-Title': 'Original Bible',
            },
            body: utf8.encode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      if (kDebugMode) debugPrint('ExplainService network failure: $e');
      throw const ExplainException(ExplainFailure.offline);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ExplainException(ExplainFailure.badKey, response.body);
    }
    if (response.statusCode == 429) {
      throw ExplainException(ExplainFailure.rateLimited, response.body);
    }
    if (response.statusCode != 200) {
      throw ExplainException(
        ExplainFailure.failed,
        'HTTP ${response.statusCode}',
      );
    }

    return _extractContent(response.bodyBytes);
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
