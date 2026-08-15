/// Knowing when the AI has stopped working well.
///
/// A hosted model can degrade without anything in our code changing: the
/// provider swaps the weights behind an id, rate limits tighten, latency
/// triples, or a reasoning model starts leaking its chain of thought into the
/// answer. None of that raises an exception — the request returns 200 and the
/// reader quietly gets something worse.
///
/// So every call records its outcome, and those records are summarised on the
/// diagnostics screen. The point is to make "we should switch models" an
/// observation rather than a hunch.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// How a single explanation turned out.
enum ExplainOutcome {
  ok,

  /// Returned 200 but the answer was unusable — empty, or visibly the model's
  /// own reasoning rather than an explanation.
  suspect,

  /// Network, timeout, auth, rate limit, or a non-200.
  error,
}

/// One recorded call.
class ExplainSample {
  const ExplainSample({
    required this.modelId,
    required this.outcome,
    required this.milliseconds,
    required this.at,
    this.note,
  });

  final String modelId;
  final ExplainOutcome outcome;
  final int milliseconds;
  final DateTime at;

  /// Short reason, for `suspect` and `error`.
  final String? note;

  Map<String, dynamic> toMap() => {
        'm': modelId,
        'o': outcome.name,
        'ms': milliseconds,
        'at': at.millisecondsSinceEpoch,
        if (note != null) 'n': note,
      };

  static ExplainSample? fromMap(Map<String, dynamic> map) {
    final outcome = ExplainOutcome.values
        .where((o) => o.name == map['o'])
        .firstOrNull;
    if (outcome == null) return null;
    return ExplainSample(
      modelId: map['m']?.toString() ?? '',
      outcome: outcome,
      milliseconds: (map['ms'] as num?)?.toInt() ?? 0,
      at: DateTime.fromMillisecondsSinceEpoch((map['at'] as num?)?.toInt() ?? 0),
      note: map['n']?.toString(),
    );
  }
}

/// Rolled-up health for one model.
class ModelHealth {
  const ModelHealth({
    required this.modelId,
    required this.total,
    required this.ok,
    required this.suspect,
    required this.errors,
    required this.medianMs,
    required this.lastFailureNote,
    required this.lastUsed,
  });

  final String modelId;
  final int total;
  final int ok;
  final int suspect;
  final int errors;
  final int medianMs;
  final String? lastFailureNote;
  final DateTime? lastUsed;

  double get successRate => total == 0 ? 1.0 : ok / total;

  /// Calls needed before a verdict is worth acting on.
  ///
  /// One failed call on a train is not a degraded model, and an alert that
  /// cries wolf gets ignored exactly when it matters.
  static const int minimumSamples = 5;

  bool get hasEnoughEvidence => total >= minimumSamples;

  /// True when this model looks like it needs replacing.
  bool get needsAttention {
    if (!hasEnoughEvidence) return false;
    return successRate < 0.8 || medianMs > 25000;
  }

  /// Plain-language summary for the diagnostics screen.
  ///
  /// Gated on the same evidence threshold as [needsAttention], so the screen
  /// never advises switching models on a sample size that would not trigger
  /// the warning next to it.
  String get verdict {
    if (total == 0) return 'Not used yet';

    if (!hasEnoughEvidence) {
      if (suspect > 0 || errors > 0) return 'Too early to tell, some problems';
      return 'Too early to tell';
    }

    if (successRate < 0.5) return 'Failing — switch model';
    if (successRate < 0.8) return 'Unreliable — consider switching';
    if (medianMs > 25000) return 'Very slow — consider switching';
    if (suspect > 0) return 'Mostly fine, some poor answers';
    return 'Healthy';
  }
}

/// Records and summarises explanation outcomes.
///
/// Stored in SharedPreferences rather than sent anywhere: this is diagnostics
/// for the app's owner, not analytics on the reader.
class ExplainHealthStore {
  ExplainHealthStore({this.maxSamples = 100});

  static const String _prefsKey = 'explainHealthSamples';

  /// Rolling window. Old samples are dropped, so a model that was bad last
  /// month does not haunt a model that is fine today.
  final int maxSamples;

  Future<void> record(ExplainSample sample) async {
    final prefs = await SharedPreferences.getInstance();
    final samples = _read(prefs)..add(sample);

    final trimmed = samples.length > maxSamples
        ? samples.sublist(samples.length - maxSamples)
        : samples;

    await prefs.setString(
      _prefsKey,
      jsonEncode(trimmed.map((s) => s.toMap()).toList()),
    );
  }

  Future<List<ExplainSample>> samples() async {
    return _read(await SharedPreferences.getInstance());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Health per model, most recently used first.
  Future<List<ModelHealth>> health() async {
    final all = await samples();
    if (all.isEmpty) return const [];

    final byModel = <String, List<ExplainSample>>{};
    for (final sample in all) {
      byModel.putIfAbsent(sample.modelId, () => []).add(sample);
    }

    final result = byModel.entries.map((entry) {
      final list = entry.value;
      final durations = list
          .where((s) => s.outcome != ExplainOutcome.error)
          .map((s) => s.milliseconds)
          .toList()
        ..sort();

      final lastFailure = list.lastWhere(
        (s) => s.outcome != ExplainOutcome.ok,
        orElse: () => list.last,
      );

      return ModelHealth(
        modelId: entry.key,
        total: list.length,
        ok: list.where((s) => s.outcome == ExplainOutcome.ok).length,
        suspect: list.where((s) => s.outcome == ExplainOutcome.suspect).length,
        errors: list.where((s) => s.outcome == ExplainOutcome.error).length,
        medianMs: durations.isEmpty
            ? 0
            : durations[durations.length ~/ 2],
        lastFailureNote:
            lastFailure.outcome == ExplainOutcome.ok ? null : lastFailure.note,
        lastUsed: list.last.at,
      );
    }).toList();

    result.sort((a, b) =>
        (b.lastUsed ?? DateTime(0)).compareTo(a.lastUsed ?? DateTime(0)));
    return result;
  }

  List<ExplainSample> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ExplainSample.fromMap)
          .whereType<ExplainSample>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Heuristics for spotting an answer that came back 200 but is not usable.
///
/// These are the actual failure shapes seen while building this: a reasoning
/// model printing its plan instead of an answer, and a truncated fragment
/// when the token budget runs out mid-thought.
class ExplainQualityCheck {
  const ExplainQualityCheck._();

  static const List<String> _reasoningTells = [
    "here's a thinking process",
    'here is a thinking process',
    'thinking process:',
    'let me analyze the request',
    '<think>',
    'step 1:',
  ];

  /// Returns a reason the answer looks wrong, or null when it looks fine.
  static String? problemWith(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'empty answer';

    final lower = trimmed.toLowerCase();
    for (final tell in _reasoningTells) {
      if (lower.contains(tell)) return 'model leaked its reasoning';
    }

    // A numbered outline where prose was asked for.
    if (RegExp(r'^\s*\d+\.\s').hasMatch(trimmed)) {
      return 'answer is an outline, not prose';
    }

    // Too short to be an explanation of anything.
    if (trimmed.length < 80) return 'answer too short';

    // Cut off mid-word or mid-clause.
    if (!RegExp(r'''[.!?"'”’)\]]\s*$''').hasMatch(trimmed)) {
      return 'answer appears truncated';
    }

    return null;
  }
}
