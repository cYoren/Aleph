/// Preparing original-language text for a platform speech engine.
///
/// Neither the Masoretic text nor the polytonic Greek can be handed to a
/// speech engine as it stands: both carry marks the engines were never built
/// to read, and both will be mispronounced or skipped outright if passed
/// through untouched.
///
/// **Hebrew.** The cantillation is removed — it is musical notation, not
/// pronunciation, and engines stumble over it. The vowel points are kept: they
/// are the whole reason to read a pointed text, and the platform voices honour
/// them. Sof pasuq becomes a full stop so the voice takes a verse-final
/// cadence, and maqaf becomes a space so joined words are spoken separately.
///
/// **Greek.** The polytonic characters are folded to monotonic (see
/// `greek_monotonic.dart`), because the engines speak modern Greek and do not
/// know the Greek Extended block at all.
///
/// The resulting pronunciation follows a living tradition rather than a
/// reconstructed one — modern Israeli Hebrew, modern Greek — which is stated
/// plainly in the app rather than glossed over.
library;

import '../../shared/utils/cantillation.dart';
import '../../shared/utils/greek_monotonic.dart';

/// Which pronunciation the bundled platform voices actually produce.
enum PronunciationTradition {
  /// Modern Israeli Hebrew, as spoken by the he-IL voices.
  modernIsraeli,

  /// Modern (Byzantine-descended) Greek, as spoken by the el-GR voices.
  modernGreek,
}

extension PronunciationTraditionLabel on PronunciationTradition {
  /// Short label for the settings screen.
  String get label => switch (this) {
    PronunciationTradition.modernIsraeli => 'Modern Israeli',
    PronunciationTradition.modernGreek => 'Modern Greek',
  };
}

/// BCP-47 tag for the voice that reads Hebrew.
const String kHebrewVoiceLanguage = 'he-IL';

/// BCP-47 tag for the voice that reads Greek.
const String kGreekVoiceLanguage = 'el-GR';

/// Voice language for a testament.
String voiceLanguageFor({required bool isHebrew}) =>
    isHebrew ? kHebrewVoiceLanguage : kGreekVoiceLanguage;

/// Folds polytonic Greek to monotonic so a modern Greek voice can read it.
String toMonotonicGreek(String text) {
  if (text.isEmpty) return text;

  final buffer = StringBuffer();
  for (final codeUnit in text.codeUnits) {
    final replacement = kGreekMonotonicFolding[codeUnit];
    if (replacement != null) {
      buffer.write(replacement);
    } else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

/// Strips the marks a Hebrew speech engine cannot read.
///
/// Cantillation goes; the vowel points stay. Set [keepVowels] to false to hand
/// the engine unpointed consonantal text and let its own diacritizer work,
/// which some Android voices prefer.
String prepareHebrewForSpeech(String text, {bool keepVowels = true}) {
  if (text.isEmpty) return text;

  final withoutAccents = stripCantillation(text);
  final buffer = StringBuffer();

  for (final codeUnit in withoutAccents.codeUnits) {
    switch (codeUnit) {
      case kSofPasuq:
        buffer.write('.');
      case kMaqaf:
      case kPaseq:
        buffer.write(' ');
      default:
        if (!keepVowels && _isVowelPoint(codeUnit)) continue;
        buffer.writeCharCode(codeUnit);
    }
  }

  return _collapseWhitespace(buffer.toString());
}

/// Niqqud and the pointing that travels with it, excluding real punctuation.
bool _isVowelPoint(int codeUnit) {
  if (codeUnit >= 0x05B0 && codeUnit <= 0x05BD) return true; // points + meteg
  if (codeUnit == 0x05BF) return true; // rafe
  if (codeUnit == 0x05C1 || codeUnit == 0x05C2) return true; // shin/sin dots
  if (codeUnit == 0x05C7) return true; // qamats qatan
  return false;
}

String _collapseWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Puts a space after sentence punctuation that lacks one.
///
/// The bundled Greek text writes every comma tight against the next word
/// ("λόγος,καὶ"). A speech engine then treats the pair as a single token and
/// runs straight through the break instead of pausing, which flattens the
/// phrasing of the whole verse.
String _spaceAfterPunctuation(String text) =>
    text.replaceAllMapped(RegExp(r'([,;·:.])(\S)'), (m) => '${m[1]} ${m[2]}');

/// Prepares one stretch of original-language text to be spoken.
String prepareForSpeech(
  String text, {
  required bool isHebrew,
  bool keepHebrewVowels = true,
}) {
  if (text.isEmpty) return text;
  return isHebrew
      ? prepareHebrewForSpeech(text, keepVowels: keepHebrewVowels)
      : _collapseWhitespace(
          _spaceAfterPunctuation(toMonotonicGreek(text)),
        );
}
