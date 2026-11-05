# Greek speech: sherpa-onnx 2 migration

The historical 1.13.8 licensing blocker is resolved in this integration by using
sherpa-onnx 2.0.1 and its lexicon frontend. This is a runtime migration, not a
notice added to the old binaries.

Primary upstream evidence:

- https://github.com/k2-fsa/sherpa-onnx/pull/4055 removes eSpeak NG and
  piper-phonemize from the runtime (merged 2026-10-20).
- https://pub.dev/packages/sherpa_onnx/changelog records removal in 2.0.0 and
  publishes 2.0.1 (2026-10-26, older than the seven-day dependency cooldown).
- The pinned v2.0.1 Dart example uses `OfflineTtsVitsModelConfig.lexicon`:
  https://github.com/k2-fsa/sherpa-onnx/blob/v2.0.1/dart-api-examples/tts/bin/piper-lexicon.dart

The original Greek model and token file keep their pinned hashes. A table of
28,475 Greek word forms is generated from all New Testament verses, Greek
tokens and lexicon lemmas. It contains IPA output only. The model remains MIT
(the original Hugging Face repository declares MIT); its dataset is CC0.
The build-time eSpeak NG executable, source and dictionary data are excluded
from Flutter assets. The bundle test asserts the exact three voice files.

`data/greek_pronunciation_lexicon.json` records generation provenance and the
content hash. `scripts/fetch_embedded_voices.py` verifies each individual file,
reuses unchanged assets and copies the generated table. Release validation
requires pronunciation coverage for every corpus form.

To reproduce with the existing local build-tool checkout, without installing
anything system-wide or using an API:

```bash
cd /home/gustvmar/Documents/Coding/Aleph
python3 scripts/build_greek_pronunciation_lexicon.py --espeak-library /home/gustvmar/Work/aleph-readiness/tools/espeak-ng/build/src/libespeak-ng/libespeak-ng.so
python3 scripts/fetch_embedded_voices.py
python3 scripts/build_greek_pronunciation_lexicon.py --check
```

The tool source is the official espeak-ng 1.52.0 tag. It is used during
preparation, not runtime. The original verified voice archive retains its
build-time data, so no new copy is distributed with the app.

The native probe produces non-silent 16 kHz WAV for John 1:1 and individual
words at ordinary and slow speeds. A reference probe on 1.13.8 confirms that
the low-quality model's long single-word output is pre-existing; this migration
does not claim native-speaker pronunciation review. Modern Greek remains the
stated pronunciation tradition. Hebrew continues to use the device voice;
adding an experimental Hebrew model is a separate feature, not a requirement
for the existing reader to work.
