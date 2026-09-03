/// Continuous recitation of a chapter in its original language.
///
/// The reader hands this notifier a chapter's verses; it speaks them in order,
/// publishing which verse is currently sounding so the reader can highlight
/// and scroll to it. Playback is driven by awaiting each utterance rather than
/// by timers, so the highlight cannot drift out of step with the voice.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/verse.dart';
import 'recitation_service.dart';
import 'recitation_text.dart';

/// How fast the voice reads, as a multiplier where 1.0 is an ordinary pace.
///
/// The slow end matters more than the fast end here: a learner following an
/// unfamiliar script needs the voice well under conversational speed to keep
/// their eye on the word being spoken.
const List<double> kRecitationRates = [0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.25];

/// Deliberately slower than speech: this is a text most users are still
/// learning to read.
const double kDefaultRecitationRate = 0.5;

/// What the player is doing.
enum RecitationStatus { idle, preparing, playing, paused, finished, failed }

class RecitationState {
  final RecitationStatus status;

  /// Chapter being recited, if any.
  final String? bookId;
  final int? chapter;

  /// Verse currently being spoken, for highlighting in the reader.
  final int? currentVerseNumber;

  /// Which voice the current run uses, so a rate change reconfigures the right
  /// one.
  final bool isHebrew;

  final double rate;

  /// Set when playback could not start, e.g. no voice installed.
  final VoiceAvailability? failure;

  const RecitationState({
    this.status = RecitationStatus.idle,
    this.bookId,
    this.chapter,
    this.currentVerseNumber,
    this.isHebrew = true,
    this.rate = kDefaultRecitationRate,
    this.failure,
  });

  bool get isActive =>
      status == RecitationStatus.playing ||
      status == RecitationStatus.preparing ||
      status == RecitationStatus.paused;

  /// Whether the transport should offer resume rather than pause.
  bool get isPaused => status == RecitationStatus.paused;

  /// True when [verseNumber] of [book]/[chapterNumber] is sounding right now.
  bool isSpeaking(String book, int chapterNumber, int verseNumber) =>
      status == RecitationStatus.playing &&
      bookId == book &&
      chapter == chapterNumber &&
      currentVerseNumber == verseNumber;

  RecitationState copyWith({
    RecitationStatus? status,
    String? bookId,
    int? chapter,
    int? currentVerseNumber,
    bool? isHebrew,
    double? rate,
    VoiceAvailability? failure,
    bool clearVerse = false,
    bool clearFailure = false,
  }) {
    return RecitationState(
      status: status ?? this.status,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      currentVerseNumber: clearVerse
          ? null
          : (currentVerseNumber ?? this.currentVerseNumber),
      isHebrew: isHebrew ?? this.isHebrew,
      rate: rate ?? this.rate,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class RecitationNotifier extends StateNotifier<RecitationState> {
  RecitationNotifier(this._service) : super(const RecitationState());

  final RecitationService _service;

  /// Bumped on every stop or restart so an utterance finishing late cannot
  /// advance a run that has already been cancelled.
  int _generation = 0;

  /// The run in progress, kept so pause, resume and verse skipping can
  /// restart it at a different point. Platform TTS cannot seek inside an
  /// utterance, so all four are the same operation: begin again at verse N.
  List<Verse> _verses = const [];
  String? _runBookId;
  int? _runChapter;
  bool _runIsHebrew = true;

  /// Reads [verses] aloud in order, from [startVerse] onwards.
  Future<void> startChapter({
    required String bookId,
    required int chapter,
    required List<Verse> verses,
    required bool isHebrew,
    int? startVerse,
  }) async {
    await stop();

    if (verses.isEmpty) return;

    _verses = verses;
    _runBookId = bookId;
    _runChapter = chapter;
    _runIsHebrew = isHebrew;

    final generation = ++_generation;
    state = state.copyWith(
      status: RecitationStatus.preparing,
      bookId: bookId,
      chapter: chapter,
      isHebrew: isHebrew,
      clearVerse: true,
      clearFailure: true,
    );

    final language = voiceLanguageFor(isHebrew: isHebrew);
    final availability = await _service.availabilityFor(language);
    if (availability != VoiceAvailability.ready) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: RecitationStatus.failed,
        failure: availability,
      );
      return;
    }

    await _service.configure(languageCode: language, rate: state.rate);
    if (generation != _generation) return;

    final startIndex = startVerse == null
        ? 0
        : verses
              .indexWhere((v) => v.verseNumber == startVerse)
              .clamp(0, verses.length - 1);

    state = state.copyWith(status: RecitationStatus.playing);

    for (int i = startIndex; i < verses.length; i++) {
      if (generation != _generation) return;

      final verse = verses[i];
      state = state.copyWith(currentVerseNumber: verse.verseNumber);

      final spoken = prepareForSpeech(verse.textContent, isHebrew: isHebrew);
      final ok = await _service.speak(spoken);

      if (generation != _generation) return;
      if (!ok) {
        state = state.copyWith(status: RecitationStatus.failed);
        return;
      }
    }

    if (generation != _generation) return;
    state = state.copyWith(status: RecitationStatus.finished, clearVerse: true);
  }

  /// Speaks a single word, for the definition sheet and vocabulary drills.
  Future<bool> speakWord(String text, {required bool isHebrew}) async {
    final language = voiceLanguageFor(isHebrew: isHebrew);
    final availability = await _service.availabilityFor(language);
    if (availability != VoiceAvailability.ready) {
      state = state.copyWith(failure: availability);
      return false;
    }

    // A single word is easier to catch a little under normal pace.
    await _service.configure(languageCode: language, rate: 0.7);
    return _service.speak(prepareForSpeech(text, isHebrew: isHebrew));
  }

  Future<void> stop() async {
    _generation++;
    await _service.stop();
    _verses = const [];
    _runBookId = null;
    _runChapter = null;
    if (!mounted) return;
    state = state.copyWith(status: RecitationStatus.idle, clearVerse: true);
  }

  /// Silences the voice but keeps the reader's place.
  ///
  /// The transport previously offered only stop, so taking a phone call
  /// during Psalm 119 meant starting the chapter again.
  Future<void> pause() async {
    if (state.status != RecitationStatus.playing) return;
    _generation++;
    await _service.stop();
    if (!mounted) return;
    state = state.copyWith(status: RecitationStatus.paused);
  }

  /// Picks the chapter back up at the verse that was sounding.
  Future<void> resume() async {
    if (!state.isPaused) return;
    await _restartAt(state.currentVerseNumber);
  }

  /// Moves [delta] verses through the chapter and carries on from there.
  Future<void> skipVerse(int delta) async {
    if (_verses.isEmpty) return;
    final current = state.currentVerseNumber;
    final index = current == null
        ? 0
        : _verses.indexWhere((v) => v.verseNumber == current);
    if (index < 0) return;

    final next = (index + delta).clamp(0, _verses.length - 1);
    await _restartAt(_verses[next].verseNumber);
  }

  Future<void> _restartAt(int? verseNumber) async {
    final bookId = _runBookId;
    final chapter = _runChapter;
    if (bookId == null || chapter == null || _verses.isEmpty) return;

    // startChapter calls stop(), which clears the run; hold on to it.
    final verses = _verses;
    final isHebrew = _runIsHebrew;
    await startChapter(
      bookId: bookId,
      chapter: chapter,
      verses: verses,
      isHebrew: isHebrew,
      startVerse: verseNumber,
    );
  }

  /// Changes the reading pace. Takes effect on the next verse.
  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
    if (state.isActive) {
      await _service.configure(
        languageCode: voiceLanguageFor(isHebrew: state.isHebrew),
        rate: rate,
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    _service.dispose();
    super.dispose();
  }
}

final recitationServiceProvider = Provider<RecitationService>((ref) {
  final service = RecitationService();
  ref.onDispose(service.dispose);
  return service;
});

final recitationProvider =
    StateNotifierProvider<RecitationNotifier, RecitationState>((ref) {
      return RecitationNotifier(ref.watch(recitationServiceProvider));
    });
