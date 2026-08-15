/// State for the opt-in AI passage explanation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';
import 'explain_health.dart';
import 'explain_model.dart';
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

/// Which model this reader gets.
final explainTierProvider = Provider<ExplainTier>((ref) {
  final pro = ref.watch(settingsProvider.select((s) => s.aiProUnlocked));
  return pro ? ExplainTier.pro : ExplainTier.free;
});

final explainModelProvider = Provider<ExplainModelConfig>((ref) {
  return modelForTier(ref.watch(explainTierProvider));
});

/// How many free explanations remain today, or null when unlimited.
final explainRemainingTodayProvider = Provider<int?>((ref) {
  final config = ref.watch(explainModelProvider);
  final limit = config.dailyLimit;
  if (limit == null) return null;

  final settings = ref.watch(settingsProvider);
  final today = _todayKey();
  final used = settings.aiExplainUsageDay == today
      ? settings.aiExplainUsedToday
      : 0;
  final remaining = limit - used;
  return remaining < 0 ? 0 : remaining;
});

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

/// Health of every model this device has actually used.
final explainHealthProvider = FutureProvider<List<ModelHealth>>((ref) async {
  return ExplainHealthStore().health();
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
  ExplainNotifier(
    this._service,
    this._languageName,
    this._config,
    this._onUsed,
  ) : super(const ExplainIdle());

  final ExplainService _service;
  final String _languageName;
  final ExplainModelConfig _config;

  /// Called after a successful free-tier call so the daily counter advances.
  final Future<void> Function() _onUsed;

  ExplainModelConfig get config => _config;

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
        config: _config,
      );
      if (generation != _generation || !mounted) return;
      state = ExplainReady(text);

      // Only a successful call counts against the free allowance; a failure
      // the reader did not get an answer from should not cost them one.
      if (!_config.isUnlimited) {
        await _onUsed();
      }
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
    ref.watch(explainModelProvider),
    () => ref.read(settingsProvider.notifier).recordAiExplainUse(),
  );
});
