# Original Bible - Deployment Guide

## 🚀 Release Status

✅ **App is ready for production deployment**

- ✅ Database built from full corpus (66 books, 31k+ verses)
- ✅ All core features implemented
- ✅ 21+ tests passing
- ✅ 0 code analysis warnings
- ✅ Fastlane configured
- ✅ Build artifacts ready

---

## 📦 What's Included

### Bible Data
- Full OT/NT original-language corpus in local SQLite
- 600k+ word tokens and 13k+ lexicon entries
- Strict-gated enabled translations:
  - `KJV` (en)
  - `LUTHER1912` (de)
  - `SYNODAL` (ru)
  - `ALMEIDA` (pt)
  - `OSTERVALD` (fr)
  - `VALERA1909` (es)
  - `CUVS` (zh)
  - `KOREAN` (ko)
- Enabled release translations must have zero canonical missing refs

### Features
- ✅ Original language text display (Hebrew/Greek)
- ✅ Word-level lexicon with tap interaction
- ✅ Side-by-side translations
- ✅ Verse bookmarking
- ✅ Full-text search
- ✅ Verse of the day
- ✅ Multi-language UI (EN, PT, DE, FR, ES, RU, ZH, KO)
- ✅ Dark mode support
- ✅ Offline-first architecture

---

## 🔨 Build Commands

### Android

**Build App Bundle (recommended for Play Store)**:
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**Build APK (for testing)**:
```bash
flutter build apk --release
```

### iOS

**Build IPA**:
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/original_bible.ipa`

**Note**: iOS builds require:
- Apple Developer account
- Valid provisioning profile
- Code signing configured in Xcode

---

## 📱 Fastlane Deployment

### Setup (One-time)

1. **Install Fastlane**:
   ```bash
   sudo gem install fastlane
   ```

2. **iOS - Create App Store Connect API Key**:
   - Go to https://appstoreconnect.apple.com/access/integrations/api
   - Create key with "App Manager" access
   - Download `.p8` file to `~/.private_keys/`

3. **Android - Create Service Account**:
   - Go to Google Play Console → API access
   - Create service account with "Release Manager" permissions
   - Download JSON key

4. **Set Environment Variables**:
   ```bash
   export APP_STORE_CONNECT_KEY_ID="YOUR_KEY"
   export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER"
   export APP_STORE_CONNECT_KEY_FILEPATH="~/.private_keys/AuthKey_XXX.p8"
   export PLAYSTORE_JSON_KEY_FILE="path/to/google-play-key.json"
   ```

### Deploy to TestFlight (iOS)
```bash
fastlane ios beta
```

### Deploy to Play Store Internal Testing (Android)
```bash
fastlane android internal
```

---

## 🎨 App Store Assets Needed

### Screenshots Required

**iOS** (Per Device Size):
- 6.9" Display (iPhone 16 Pro Max): 1320x2868
- 6.7" Display (iPhone 14 Pro Max): 1290x2796
- 6.5" Display (iPhone 14 Plus): 1284x2778
- 5.5" Display (iPhone 8 Plus): 1242x2208
- iPad Pro 12.9": 2048x2732

**Android**:
- Phone: 1080x1920 or higher
- 7" Tablet: 1024x600 or higher
- 10" Tablet: 1280x800 or higher

### App Store Listing

**Short Description** (80 chars):
```
Hebrew & Greek Bible with word-level lexicon. Offline-first, scholar-focused.
```

**Full Description**:
```
Original Bible brings the Hebrew and Greek scriptures to your device with:

ORIGINAL LANGUAGE TEXT
• Masoretic Hebrew text (Old Testament)
• Textus Receptus Greek (New Testament)
• Word-by-word lexicon and morphology
• Tap any word for instant definitions

SIDE-BY-SIDE TRANSLATIONS
• Compare original text with selected translation language
• Enabled translations: KJV, Luther 1912, Synodal, Almeida, Ostervald, Valera 1909, CUVS, KOREAN
• Strict-coverage rollout gate prevents partial translations from appearing in UI

STUDY FEATURES
• Bookmark favorite verses
• Full-text search across all books
• Verse of the day from notable passages
• Offline-first - no internet required

SCHOLAR-FRIENDLY
• Clean interface without ads
• Designed for serious Bible study
• Supports ministers, students, and scholars
• 100% offline - your data stays private

MULTI-LANGUAGE INTERFACE
• English, Portuguese, German, French, Spanish, Russian, Chinese (Simplified), Korean

Perfect for seminary students, pastors, missionaries, and anyone wanting to study the Bible in its original languages.
```

**Keywords** (max 100 chars):
```
Bible,Hebrew,Greek,Study,Lexicon,Scripture,Torah,Gospel,Offline,Scholar,Seminary,Pastor,Theology
```

**Categories**:
- Primary: Reference
- Secondary: Education

**Age Rating**:
- 4+ (No objectionable content)

---

## 🔐 Privacy Policy

**Privacy URL**: You'll need to create a privacy policy page. Sample content:

```
Privacy Policy for Original Bible

Last updated: [DATE]

TLDR: We don't collect any data. Everything is stored locally on your device.

DATA COLLECTION
Original Bible does not collect, transmit, or store any user data on external servers.

LOCAL STORAGE
- Bible text and translations are stored locally on your device
- Your bookmarks, settings, and reading history are saved locally
- No data is sent to our servers or third parties

NO TRACKING
- No analytics or crash reporting
- No advertising networks
- No user profiling

PERMISSIONS
- Storage: Required to save Bible data and user preferences locally
- None of your data leaves your device

CONTACT
For questions: [your-email@example.com]
```

---

## 📝 Release Checklist

### Pre-Submission
- [ ] Test on physical devices (iOS + Android)
- [ ] Verify full-corpus verses display correctly across OT/NT
- [ ] Test lexicon tap interaction
- [ ] Test bookmark functionality
- [ ] Test search feature
- [ ] Verify translations switch properly
- [ ] Test dark mode
- [ ] Check all 8 language localizations (EN, PT, DE, FR, ES, RU, ZH, KO)
- [ ] Run `flutter analyze` (should show 0 issues)
- [ ] Run `flutter test`

### App Store Connect (iOS)
- [ ] Create app listing
- [ ] Upload screenshots (5 device sizes)
- [ ] Add app icon (1024x1024)
- [ ] Write description and keywords
- [ ] Set category: Reference
- [ ] Add privacy policy URL
- [ ] Set age rating: 4+
- [ ] Upload build via Fastlane or manual
- [ ] Submit for review

### Google Play Console (Android)
- [ ] Create app listing
- [ ] Upload screenshots (phone + tablet)
- [ ] Add feature graphic (1024x500)
- [ ] Add app icon (512x512)
- [ ] Write description and keywords
- [ ] Set category: Books & Reference
- [ ] Add privacy policy URL
- [ ] Set content rating: Everyone
- [ ] Upload AAB via Fastlane or manual
- [ ] Release to Internal Testing first
- [ ] Promote to Production after testing

---

## 🐛 Known Limitations

### Current Database Scope
- Japanese translation (`KOUGO`) remains intentionally disabled and hidden in this release.
- Learning Mode interactive replacement is currently English-only for translation text.

For production builds:
1. Regenerate `assets/bible.db` with `scripts/build_full_bible_db.py`.
2. Compact it and write the packed asset with `scripts/prepare_bible_db.py`.
3. Run `./scripts/validate_release.sh`.
4. Run `flutter analyze` and `flutter test`.

### Future Enhancements
See `FEATURES_AND_RECOMMENDATIONS.md` for v1.1+ roadmap:
- Reading plans
- Study notes & highlights
- Cross-references
- Audio Bible
- Additional strict-gated translations

---

## 📊 Analytics (Optional)

If you want to add analytics later:
- **Firebase Analytics** (free, privacy-friendly)
- **Sentry** (crash reporting)
- Keep it **opt-in** and respect privacy-first philosophy

---

## 🆘 Troubleshooting

### iOS Build Fails
```
Error: No profiles for 'com.medicinahub.originalbible' were found
```

**Fix**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Select your Development Team
4. Let Xcode auto-manage provisioning profiles

### Android Build Fails (Signing)
```
Error: No key.properties file found
```

**Fix**:
```bash
cd android
cp key.properties.example key.properties
# Edit key.properties with your keystore details
```

### Database Not Found
```
Error: assets/bible.db.gz not found
```

The app ships the compressed asset, so a database that was built but never
packed fails the build.

**Fix**:
```bash
python3 scripts/build_full_bible_db.py --output assets/bible.db \
  --cache-dir /tmp/original_bible_db_cache --strict-coverage --fill-kjv-gaps
python3 scripts/prepare_bible_db.py
./scripts/validate_release.sh
# Should show: OK: database asset and full-release integrity checks passed.
```

---

## 📈 Post-Launch

### Monitor
- App Store reviews
- Crash reports (if analytics enabled)
- User feedback emails

### Update Strategy
1. **v1.0.1** - Bug fixes only
2. **v1.1** - Reading plans feature
3. **v1.2** - Study notes & highlights
4. **v2.0** - Audio Bible + cloud sync (optional)

### Marketing Ideas
- Submit to seminary newsletters
- Post in Biblical languages forums
- Reach out to theology professors
- Create demo video showing lexicon feature
- Write blog post about original language Bible study

---

## ✅ You're Ready!

The app is production-ready. Build artifacts can be generated with:
```bash
flutter build appbundle --release  # Android
flutter build ipa --release        # iOS
```

Or use Fastlane for automated deployment:
```bash
fastlane ios beta      # TestFlight
fastlane android internal  # Play Store Internal
```

Good luck with your release! 🚀
