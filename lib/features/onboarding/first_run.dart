/// The first ten minutes, measured.
///
/// A reader who has never seen a Hebrew letter needs a path in, and a path is
/// only real if it is short enough to finish. This keeps the clock: when the app
/// was first opened, when the letters step was passed, when the first verse was
/// read, and when the first five words were reviewed. `/start` shows the result
/// as a number rather than a claim.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/usage_events.dart';

const _launchKey = 'firstRunLaunchAt';
const _lettersKey = 'firstRunLettersAt';
const _verseKey = 'firstRunVerseAt';
const _reviewKey = 'firstRunReviewAt';

class FirstRunState {
  /// First launch on this device. The clock starts here, not after onboarding.
  final DateTime? launchedAt;
  final DateTime? lettersAt;
  final DateTime? verseAt;
  final DateTime? reviewAt;

  /// False until the stored stamps have been read. The startup gate waits for
  /// this, otherwise a returning reader whose steps are long done is briefly
  /// routed into the on-ramp on every launch.
  final bool isLoaded;

  const FirstRunState({
    this.launchedAt,
    this.lettersAt,
    this.verseAt,
    this.reviewAt,
    this.isLoaded = false,
  });

  bool get hasReadFirstVerse => verseAt != null;
  bool get hasReviewedFirstWords => reviewAt != null;

  /// The whole on-ramp is behind the reader: the card on the home screen goes
  /// away for good.
  bool get isComplete => hasReadFirstVerse && hasReviewedFirstWords;

  /// Minutes from first launch to the first verse they could actually read.
  /// Null until that verse is behind them.
  int? get minutesToFirstVerse {
    final start = launchedAt;
    final end = verseAt;
    if (start == null || end == null) return null;
    final seconds = end.difference(start).inSeconds;
    if (seconds < 0) return null;
    return seconds < 60 ? 0 : (seconds / 60).round();
  }

  FirstRunState copyWith({
    DateTime? launchedAt,
    DateTime? lettersAt,
    DateTime? verseAt,
    DateTime? reviewAt,
  }) {
    return FirstRunState(
      launchedAt: launchedAt ?? this.launchedAt,
      lettersAt: lettersAt ?? this.lettersAt,
      verseAt: verseAt ?? this.verseAt,
      reviewAt: reviewAt ?? this.reviewAt,
      isLoaded: isLoaded,
    );
  }
}

final firstRunProvider = StateNotifierProvider<FirstRunNotifier, FirstRunState>(
  (ref) => FirstRunNotifier(),
);

class FirstRunNotifier extends StateNotifier<FirstRunState> {
  FirstRunNotifier() : super(const FirstRunState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final launched = prefs.getInt(_launchKey);
    if (!mounted) return;
    state = FirstRunState(
      launchedAt: launched == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(launched),
      lettersAt: _read(prefs, _lettersKey),
      verseAt: _read(prefs, _verseKey),
      reviewAt: _read(prefs, _reviewKey),
      isLoaded: true,
    );
  }

  DateTime? _read(SharedPreferences prefs, String key) {
    final value = prefs.getInt(key);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  /// Stamps the first launch, once. Called from the startup gate so the clock
  /// covers onboarding too.
  Future<void> touchLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_launchKey) != null) return;
    final now = DateTime.now();
    await prefs.setInt(_launchKey, now.millisecondsSinceEpoch);
    if (mounted) state = state.copyWith(launchedAt: now);
  }

  Future<void> completeLetters() => _stamp(_lettersKey, state.lettersAt);

  Future<void> completeVerse() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_verseKey) == null) {
      await prefs.setInt(_verseKey, now.millisecondsSinceEpoch);
    }
    if (mounted) {
      state = state.copyWith(
        verseAt: state.verseAt ?? now,
        launchedAt: state.launchedAt ?? now,
      );
    }
    UsageEvents.record(UsageEvent.firstVerseRead);
  }

  Future<void> completeReview() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_reviewKey) == null) {
      await prefs.setInt(_reviewKey, now.millisecondsSinceEpoch);
    }
    if (mounted) state = state.copyWith(reviewAt: state.reviewAt ?? now);
    UsageEvents.record(UsageEvent.firstReviewDone);
  }

  /// "Start again" on the closing card: the steps repeat, the first-launch
  /// stamp does not (the measurement stays true to the first time).
  Future<void> restart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lettersKey);
    await prefs.remove(_verseKey);
    await prefs.remove(_reviewKey);
    if (mounted) {
      state = FirstRunState(launchedAt: state.launchedAt, isLoaded: true);
    }
  }

  Future<void> _stamp(String key, DateTime? existing) async {
    if (existing != null) return;
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, now.millisecondsSinceEpoch);
    if (!mounted) return;
    if (key == _lettersKey) {
      state = state.copyWith(lettersAt: now);
    }
  }
}
