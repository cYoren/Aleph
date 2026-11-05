# Contributing to Original Bible

First off, thank you for your interest in contributing to **Original Bible**! Contributions are what make the open-source community such an amazing place to learn, inspire, and create.

We want to make contributing to this project as easy and safe as possible. Please read the guidelines below to get started.

---

## 🛠️ Setting Up Your Development Environment

### Prerequisites
Before you start, make sure you have installed:
- **Flutter SDK** (stable channel)
- **Dart SDK** (included with Flutter)
- **Python 3.9+** (required to compile the SQLite Bible database)
- **SQLite CLI** (`sqlite3`)
- **Xcode** (for iOS/macOS development, macOS host required)
- **Android Studio + Android SDK** (for Android development)

### Step 1: Clone and Install Dependencies
1. Clone the repository and navigate to the directory.
2. Install the Flutter package dependencies:
   ```bash
   flutter pub get
   ```

### Step 2: Build the Local Bible Database
The SQLite database file `assets/bible.db` is ignored in Git. You must build it locally to run the application:
```bash
python3 scripts/build_full_bible_db.py \
  --output assets/bible.db \
  --cache-dir /tmp/original_bible_db_cache \
  --strict-coverage \
  --fill-kjv-gaps \
  --emit-coverage-report build/coverage_report.json
```

Then compact the database and write the compressed asset the app bundles.
`pubspec.yaml` ships `assets/bible.db.gz`, so a build fails without this step:
```bash
python3 scripts/prepare_bible_db.py
```

### Step 3: Run the App
With the database in place, run the project on your preferred target device:
```bash
flutter run
```

---

## 🧪 Quality Control & Testing

Before submitting a Pull Request, please ensure that your changes pass all local verification gates:

1. **Format Check**:
   Format all Dart files using the standard formatting rules:
   ```bash
   dart format .
   ```

2. **Static Analysis**:
   Ensure there are no analyzer warnings or info messages:
   ```bash
   flutter analyze
   ```

3. **Run Unit & Widget Tests**:
   Run all automated tests:
   ```bash
   flutter test
   ```

4. **Verify Database Readiness**:
   Run the release validation script to ensure that local database generation passes all translation and corpus checks:
   ```bash
   ./scripts/validate_release.sh
   ```

---

## 🤝 How to Submit Changes

1. **Find or Create an Issue**: Discuss major additions or changes via issues before starting work to align on implementation design.
2. **Branch Naming**: Use descriptive names, e.g., `feature/reading-plans` or `bugfix/fix-lexicon-spacing`.
3. **Commit Messages**: Keep commit messages clear and descriptive.
4. **Submit a Pull Request**: Provide a detailed summary of what your changes do, what was tested, and how to verify them.

Thank you again for contributing!
