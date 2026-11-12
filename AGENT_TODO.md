# Aleph integration verification

The old 1.0.6 billing/release instructions in this file were historical and are
superseded by the current README build recipe and the local verification report.
Do not trigger GitHub builds or submit a store release from this checklist.

Current integration: `design/reading-activation-polish`, PR #8.

- [x] Integrate the compressed database reader and packed-only asset manifest.
- [x] Verify all 31,152 canonical syntax records, with no missing or extra verses.
- [x] Keep the Bible and seven translated short-gloss languages complete.
- [x] Integrate Android edge-to-edge and resource shrinking fixes.
- [x] Preserve the existing visual identity while finishing first-reading flow.
- [x] Adapt navigation and language selection for tablets, landscape and large text.
- [x] Replace the old speech runtime with sherpa-onnx 2 and generated pronunciations.
- [x] Exclude eSpeak code and dictionary data from the app bundle.
- [x] Make data/font/voice attributions available offline in Settings.
- [x] Keep the AI tutor off until a new reader explicitly enables it.
- [ ] Record final Android, iOS and macOS native build/interaction evidence.
- [ ] Reconcile final review comments and merge the verified source integration.

No new model, translation service, paid API or GitHub Actions build is required.
The two local long-form translation commits remain preserved on their original
feature branch; the four remaining language caches are a separate content task.
Fallback English dictionary entries remain explicitly labeled in the app.
