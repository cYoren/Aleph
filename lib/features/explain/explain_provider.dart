/// State for the opt-in AI passage explanation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';
import 'explain_service.dart';

/// Answer in the reader's own interface language, so a Portuguese reader gets
/// a Portuguese explanation rather than an English one about a Hebrew verse.
const Map<String, String> kExplainLanguageNames = {
  'en': 'English',
  'pt': 'Portuguese',
  'de': 'German',
  'fr': 'French',
  'es': 'Spanish',
  'ru': 'Russian',
  'zh': 'Simplified Chinese',
  'ko': 'Korean',
};

final explainServiceProvider = Provider<ExplainService>((ref) {
  final service = ExplainService();
  ref.onDispose(service.dispose);
  return service;
});

/// Whether the explain feature should appear at all.
///
/// Requires both a compiled-in key and the reader having switched it on. With
/// no key the switch is hidden too, so an unconfigured build looks like a
/// clean offline app rather than a broken feature.
final explainAvailableProvider = Provider<bool>((ref) {
  final configured = ref.watch(explainServiceProvider).isConfigured;
  final enabled = ref.watch(settingsProvider.select((s) => s.aiExplainEnabled));
  return configured && enabled;
});

/// True when the build could support explanations, regardless of the toggle —
/// used to decide whether to show the setting itself.
final explainConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(explainServiceProvider).isConfigured;
});

class ExplainRequest {
  const ExplainRequest({
    required this.reference,
    required this.originalText,
    required this.translationText,
    required this.isHebrew,
  });

  final String reference;
  final String originalText;
  final String translationText;
  final bool isHebrew;
}

sealed class ExplainState {
  const ExplainState();
}

class ExplainIdle extends ExplainState {
  const ExplainIdle();
}

class ExplainLoading extends ExplainState {
  const ExplainLoading();
}

class ExplainReady extends ExplainState {
  const ExplainReady(this.text);
  final String text;
}

class ExplainFailed extends ExplainState {
  const ExplainFailed(this.failure);
  final ExplainFailure failure;
}

class ExplainNotifier extends StateNotifier<ExplainState> {
  ExplainNotifier(this._service, this._languageName)
      : super(const ExplainIdle());

  final ExplainService _service;
  final String _languageName;

  /// Guards against a slow response landing after the reader moved on.
  int _generation = 0;

  Future<void> request(ExplainRequest request) async {
    final generation = ++_generation;
    state = const ExplainLoading();

    try {
      final text = await _service.explain(
        reference: request.reference,
        originalText: request.originalText,
        translationText: request.translationText,
        isHebrew: request.isHebrew,
        languageName: _languageName,
      );
      if (generation != _generation || !mounted) return;
      state = ExplainReady(text);
    } on ExplainException catch (e) {
      if (generation != _generation || !mounted) return;
      state = ExplainFailed(e.failure);
    } catch (_) {
      if (generation != _generation || !mounted) return;
      state = const ExplainFailed(ExplainFailure.failed);
    }
  }

  void reset() {
    _generation++;
    if (mounted) state = const ExplainIdle();
  }
}

final explainProvider =
    StateNotifierProvider<ExplainNotifier, ExplainState>((ref) {
  final language = ref.watch(settingsProvider.select((s) => s.appLanguage));
  return ExplainNotifier(
    ref.watch(explainServiceProvider),
    kExplainLanguageNames[language] ?? 'English',
  );
});
