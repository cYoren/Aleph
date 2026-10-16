# Embedded voices: findings, licensing and evidence

Status: **Greek shipped and working offline in the app bundle. Hebrew is
blocked on licensing and deliberately not shipped.** Device playback is not yet
verified (no iOS/Android hardware here) — see "What is still pending".

This is the reasoning behind `lib/features/audio/embedded_voices.dart` and
`scripts/fetch_embedded_voices.py`. Read it before changing either.

## What was asked and what is true

The goal was a Modern Israeli Hebrew (`he-IL`) and a Modern Greek (`el-GR`)
voice that travel *inside* the app: no download, no internet, works on the very
first run. Downloading a voice on first use does not count.

* **Greek — done.** The app bundles a Piper VITS voice and synthesizes with it
  offline. Nothing is downloaded at runtime.
* **Hebrew — not possible today.** No Hebrew TTS voice with a license that
  permits redistribution in a store app is known to exist. Hebrew therefore
  keeps the device voice. This is stated in Settings, not hidden.

Do not describe both voices as ready. Only the Greek voice is.

## The Greek voice

| | |
|---|---|
| Voice | `el_GR/rapunzelina` (Piper, low quality) |
| Language | Modern Greek (Greece) |
| Sample rate | 16 kHz, single speaker |
| Engine | `sherpa_onnx` (Apache-2.0), Rust/C++ ONNX runtime under the hood |
| Weights license | MIT — from the `rhasspy/piper-voices` repository (tagged `license: mit`) |
| Training data | Rapunzelina Greek single-speaker corpus, **CC0** |
| Phonemizer | eSpeak NG — data is **GPL-3.0** (see the obligation below) |
| Download | `vits-piper-el_GR-rapunzelina-low.tar.bz2` |
| SHA-256 | `bb868070a9ba0d7220b3d7c9291a998c2f60accdb73525bd63b8751b86dd4839` |
| Size on disk | ~79 MB extracted (model ~64 MB + eSpeak data ~7 MB + tokens) |

The hash matches both the sherpa-onnx release asset and the community registry
`AACTools/sherpa-onnx-tts-models`.

### Copyleft obligation (must be honoured)

Piper voices are phonemized with eSpeak NG, whose *data* is GPL-3.0. Shipping
that data is permitted but carries a notice obligation. The attribution is
recorded in `assets/voices/manifest.json` and must appear in the app's credits /
NOTICE file. If a GPL-free phonemizer is ever required, the alternative is a
voice that does not use eSpeak (for example an MMS-style model) — but those are
currently non-commercial, so they do not help Hebrew either.

### Smaller alternatives

The same voice ships in int8 (~20 MB) and fp16 (~34 MB) builds with their own
published hashes. They were **not** selected because their pronunciation quality
cannot be judged here; switch by adding the variant's URL and hash to
`scripts/fetch_embedded_voices.py` and updating the asset paths. The fp32 voice
is the fidelity-safe default.

## Why Hebrew has no bundled voice

Every candidate fails a hard requirement: a license that permits redistribution,
a model small enough for a phone, and an ONNX/mobile runtime. Survey:

| Candidate | License | Why not |
|---|---|---|
| Piper `he_IL/saspeech/medium` | non-commercial (SASPEECH, OpenSLR 134) | Training data is "Custom non-commercial". Cannot ship. |
| `Yzamari/f5tts-hebrew-v2` | Apache-2.0 | F5-TTS diffusion, ~0.3 B params, F32 (~1.2 GB); not ONNX; trained partly on non-commercial data. Too big and legally unclear. |
| `notmax123/Zonos-Hebrew` | CC-BY-NC-4.0 | Non-commercial. |
| Meta MMS `heb` | CC-BY-NC-4.0 | Non-commercial. |
| `thewh1teagle/ILSpeech` dataset | MIT | An **MIT Hebrew speech dataset** exists, but no mobile-sized ONNX model has been trained and released from it. This is the most promising path to a future shippable voice. |

If an ILSpeech-trained (or otherwise permissively licensed) Hebrew VITS model
appears, add it to `kEmbeddedVoices` — the engine and the service already
support it with no code change.

## How the app uses it

* `RecitationService` prefers the bundled voice where one exists and the
  platform is Android or iOS; the device voice is the fallback for Hebrew and
  for macOS (which ships high-quality voices with the OS). The choice is
  invisible to the chapter player.
* Synthesis runs in a **dedicated background isolate** so a long verse never
  blocks the reader; the UI thread only sends text and receives PCM.
* The voice's assets are copied once from the app bundle to the app-support
  directory (stamped by `kBundledVoiceVersion`) because the native library needs
  real file paths, not `AssetBundle` handles.
* On the iOS path the existing `playback` audio session and `UIBackgroundModes:
  audio` still apply, so the silent switch and screen lock do not silence it.

## Evidence produced here

* Reproducible fetch with pinned URL + SHA-256:
  `python3 scripts/fetch_embedded_voices.py` (verified both hashes).
* A real Linux `flutter build linux --debug` with `sherpa_onnx` + `audioplayers`
  linked (`libsherpa-onnx-c-api.so`, `libonnxruntime.so`).
* The **same Dart package and native libraries** the app uses, driven end to end
  by `tool/embedded_tts_probe.dart`, producing real 16 kHz WAV for John 1:1 and
  isolated words at normal and learner speeds:
  `LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib dart run tool/embedded_tts_probe.dart`
* Independent Python synthesis (`sherpa-onnx` 1.13.8) samples with measured
  speech energy (RMS 0.02–0.04, 20–50 % voiced), used to sanity-check that audio
  is produced and not silence.

## What is still pending

* **Device playback on iPhone and Android.** Not tested: this machine has no
  Xcode, no Android SDK, and no phone. Compiling on Linux does not prove sound
  on a device. The silent-switch and locked-screen behavior must be re-checked
  on a real iPhone once the bundled engine is live.
* **Native-speaker audio review.** The samples are real but unreviewed. Modern
  Greek pronunciation quality for the low-quality Piper voice is unknown.
* **App-size budget.** +~79 MB (fp32). A final choice between fp32/int8/fp16 is
  the maintainer's call.
* **Hebrew replacement.** Blocked until a permissively licensed Hebrew voice
  exists.
