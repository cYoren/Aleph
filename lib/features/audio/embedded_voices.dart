/// The voices bundled **inside** the app, and the one that deliberately is not.
///
/// Recitation used to depend entirely on a Hebrew or Greek voice the reader had
/// installed in the operating system. On Android that voice usually is not
/// there, so tapping play offered an "Install voice data" button and the reader
/// had to go and find it. This file names the voices that instead travel with
/// the app, so `RecitationService` can prefer them and only fall back to the
/// device when a language genuinely has none.
///
/// See `docs/tasks/embedded-voices-findings.md` for the licensing survey behind
/// these choices, and `scripts/fetch_embedded_voices.py` for the pinned
/// downloads.
library;

/// A VITS voice shipped in the application bundle.
class EmbeddedVoice {
  const EmbeddedVoice({
    required this.id,
    required this.languageCode,
    required this.isHebrew,
    required this.sampleRate,
    required this.license,
    required this.attribution,
    required this.modelAsset,
    required this.tokensAsset,
    required this.dataDirAsset,
  });

  /// Stable identifier, also the directory name under `assets/voices/`.
  final String id;

  /// BCP-47 language tag this voice speaks.
  final String languageCode;

  final bool isHebrew;

  /// Sampling rate of the model's output, in Hz.
  final int sampleRate;

  /// Human-readable license summary, shown in attribution notes.
  final String license;
  final String attribution;

  /// Asset paths as declared in `pubspec.yaml`.
  final String modelAsset;
  final String tokensAsset;
  final String dataDirAsset;
}

const String _elId = 'el_GR-rapunzelina-low';
const String _elBase = 'assets/voices/$_elId';

/// The bundled Greek voice: Piper `el_GR/rapunzelina` (Modern Greek).
///
/// Redistributable: the Piper voice weights come from the MIT-licensed
/// `rhasspy/piper-voices` repository, the training data is the CC0 Rapunzelina
/// corpus, and the phonemizer data is eSpeak NG (GPL-3.0, notice kept).
const EmbeddedVoice kEmbeddedGreekVoice = EmbeddedVoice(
  id: _elId,
  languageCode: 'el-GR',
  isHebrew: false,
  sampleRate: 16000,
  license: 'MIT weights / CC0 data / GPL-3.0 eSpeak NG data',
  attribution:
      'Piper el_GR/rapunzelina (rhasspy/piper-voices, MIT; data CC0), '
      'converted by sherpa-onnx. Phonemizer: eSpeak NG (GPL-3.0).',
  modelAsset: '$_elBase/el_GR-rapunzelina-low.onnx',
  tokensAsset: '$_elBase/tokens.txt',
  dataDirAsset: '$_elBase/espeak-ng-data',
);

/// Every bundled voice, keyed by language tag.
const Map<String, EmbeddedVoice> kEmbeddedVoices = {
  'el-GR': kEmbeddedGreekVoice,
};

/// Why Hebrew has no bundled voice.
///
/// The only Piper Hebrew voice (`he_IL/saspeech/medium`) was trained on the
/// SASPEECH corpus (OpenSLR 134), whose licence is *"Custom non-commercial"*.
/// It cannot be redistributed in an app distributed through the App Store or
/// Play Store, and no permissively-licensed, mobile-sized Hebrew TTS model is
/// validated for this project. Hebrew therefore keeps the device voice as its path, and
/// this string is the honest reason, shown in Settings.
const String kHebrewEmbeddedVoiceUnavailableReason =
    'No Hebrew voice with a license that permits redistribution is available '
    'yet, so Hebrew uses your device voice.';

/// The bundled voice for a testament, or null when there is none.
EmbeddedVoice? embeddedVoiceFor({required bool isHebrew}) =>
    isHebrew ? null : kEmbeddedVoices['el-GR'];
