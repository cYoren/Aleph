# Open Source App Store Publishing Guide

This guide explains how to release and publish updates for the open-source version of **Original Bible** across various open-source platforms (GitHub Releases, F-Droid, and KDE Store) in a deterministic, automated way.

---

## 📦 1. GitHub Releases (Automated CI/CD)

Whenever you push a version tag (e.g., `v1.0.0`), the configured GitHub Actions workflow (`.github/workflows/release.yml`) automatically triggers to compile the database, run code generation, build the release APK and App Bundle (AAB), and publish them.

### Optional: Configure Production Signing Key
By default, if no secrets are configured, the workflow builds using Android's **debug key** as a fallback. To make the workflow output officially signed production APKs/AABs, add the following two **Repository Secrets** in your GitHub repository settings (`Settings -> Secrets and variables -> Actions`):

1. **`ANDROID_KEYSTORE_BASE64`**:
   Convert your `.jks` or `.keystore` file to a Base64 string and paste the output:
   ```bash
   base64 -i path/to/your/upload-keystore.jks | pbcopy
   ```

2. **`ANDROID_KEY_PROPERTIES`**:
   The exact content of your production `key.properties` file:
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=your_key_alias
   storeFile=../upload-keystore.jks
   ```

Once these secrets are added, all future tagged release builds on GitHub Actions will be signed with your official production key.

---

## 🤖 2. F-Droid (Source-Built Store)

F-Droid is the largest open-source Android app index. Rather than uploading pre-built APKs, F-Droid compiles applications directly from source on their own build servers.

### How to Submit to F-Droid
1. Fork the [fdroiddata repository](https://gitlab.com/fdroid/fdroiddata).
2. Create a new metadata file for the app at `templates/com.originalbible.original_bible.yml` (or `.txt`).
3. Add the build recipe configuration to the metadata file. Here is a recommended build recipe template:

```yaml
Categories:
  - Reading
  - Reference
License: MIT
AuthorName: Gustavo Marcelino
WebSite: https://github.com/cYoren/Aleph
SourceCode: https://github.com/cYoren/Aleph
IssueTracker: https://github.com/cYoren/Aleph/issues

RepoType: git
Repo: https://github.com/cYoren/Aleph.git

Builds:
  - versionName: 1.0.0
    versionCode: 19
    commit: v1.0.0
    subdir: .
    sudo:
      - apt-get update && apt-get install -y python3 sqlite3
    srclib:
      - flutter@stable
    prebuild:
      - $$flutter$$ pub get
      - python3 scripts/build_full_bible_db.py --output assets/bible.db --cache-dir /tmp/cache --strict-coverage --fill-kjv-gaps
      - python3 scripts/prepare_bible_db.py
    build:
      - $$flutter$$ build apk --release
```

4. Submit a Merge Request to `fdroiddata`. Once merged, F-Droid's build checkers will automatically scan your GitHub repository tags, build new versions, and publish them to the F-Droid store client.

---

## 🎨 3. KDE Store / Pling Store

The KDE Store (OpenDesktop/pling.com) is a popular open-source software directory that hosts mobile applications.

### How to Publish
1. Go to the [KDE Store (pling.com)](https://www.pling.com/) and register or sign in.
2. Click **Add Product** and select the category **Mobile Applications -> Android**.
3. Fill in the title, description (you can copy the text from `DEPLOYMENT.md` or `README.md`), and upload screenshots.
4. Under the **Files** section, instead of uploading a static APK file directly, select **Add Link**.
5. Set the Link URL to dynamically point to your latest GitHub release:
   `https://github.com/cYoren/Aleph/releases/latest/download/app-release.apk`
6. Give it a label like `Download Latest Release APK`.

### How Updates Work
Because the link dynamically targets `/releases/latest/download/app-release.apk`, **you never need to manually log in and update the KDE Store.** 
Whenever you push a new release tag, GitHub Actions will compile the new APK and overwrite the `latest` asset. Anyone downloading the app from the KDE Store will immediately get the newest version automatically!
