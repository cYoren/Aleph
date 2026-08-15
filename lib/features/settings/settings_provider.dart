import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/utils/hebrew_display.dart';

// Language to default translation mapping (applied during onboarding only).
const Map<String, String> languageToTranslation = {
  'en': 'KJV',
  'pt': 'ALMEIDA',
  'de': 'LUTHER1912',
  'fr': 'OSTERVALD',
  'es': 'VALERA1909',
  'ru': 'SYNODAL',
  'zh': 'CUVS',
  'ko': 'KOREAN',
};

const Set<String> _supportedTranslationIds = {
  'KJV',
  'ALMEIDA',
  'SYNODAL',
  'VALERA1909',
  'OSTERVALD',
  'LUTHER1912',
  'CUVS',
  'KOUGO',
  'KOREAN',
};
const Set<String> _supportedAppLanguages = {
  'en',
  'pt',
  'de',
  'fr',
  'es',
  'ru',
  'zh',
  'ko',
};

String normalizeAppLanguage(String? languageCode) {
  final normalized = (languageCode ?? '').trim().toLowerCase();
  if (_supportedAppLanguages.contains(normalized)) {
    return normalized;
  }
  return 'en';
}

String normalizeTranslationCode(String? code) {
  final normalized = (code ?? '').trim().toUpperCase();
  if (_supportedTranslationIds.contains(normalized)) {
    return normalized;
  }
  return 'KJV';
}

String defaultTranslationForLanguage(String languageCode) {
  final normalizedLanguage = normalizeAppLanguage(languageCode);
  return normalizeTranslationCode(
    languageToTranslation[normalizedLanguage] ?? 'KJV',
  );
}

// State model
class SettingsState {
  final ThemeMode themeMode;
  final double fontSize;
  final String translation;
  final String lastReadBook;
  final int lastReadChapter;
  final bool showPronunciation;
  final String appLanguage;
  final bool hasCompletedOnboarding;
  final bool learningModeEnabled;
  final bool readerModeEnabled;
  final HebrewTextDisplay hebrewTextDisplay;

  /// Space the Hebrew text at the Masoretic disjunctive accents, so a verse
  /// reads as phrases rather than a flat row of words.
  final bool showSenseUnits;

  /// Whether the reader has dismissed the one-time hint about tap /
  /// long-press / recite. Onboarding teaches the same affordances, but a
  /// user who taps Skip there should still learn them somewhere.
  final bool hasSeenReadingHint;

  final bool hasManuallySelectedTranslation;
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 18.0,
    this.translation = 'KJV',
    this.lastReadBook = 'GEN',
    this.lastReadChapter = 1,
    this.showPronunciation = false,
    this.appLanguage = 'en',
    this.hasCompletedOnboarding = false,
    this.learningModeEnabled = false,
    this.readerModeEnabled = false,
    this.hebrewTextDisplay = HebrewTextDisplay.full,
    this.showSenseUnits = true,
    this.hasSeenReadingHint = false,
    this.hasManuallySelectedTranslation = false,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    String? translation,
    String? lastReadBook,
    int? lastReadChapter,
    bool? showPronunciation,
    String? appLanguage,
    bool? hasCompletedOnboarding,
    bool? learningModeEnabled,
    bool? readerModeEnabled,
    HebrewTextDisplay? hebrewTextDisplay,
    bool? showSenseUnits,
    bool? hasSeenReadingHint,
    bool? hasManuallySelectedTranslation,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      translation: translation ?? this.translation,
      lastReadBook: lastReadBook ?? this.lastReadBook,
      lastReadChapter: lastReadChapter ?? this.lastReadChapter,
      showPronunciation: showPronunciation ?? this.showPronunciation,
      appLanguage: appLanguage ?? this.appLanguage,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      learningModeEnabled: learningModeEnabled ?? this.learningModeEnabled,
      readerModeEnabled: readerModeEnabled ?? this.readerModeEnabled,
      hebrewTextDisplay: hebrewTextDisplay ?? this.hebrewTextDisplay,
      showSenseUnits: showSenseUnits ?? this.showSenseUnits,
      hasSeenReadingHint: hasSeenReadingHint ?? this.hasSeenReadingHint,
      hasManuallySelectedTranslation:
          hasManuallySelectedTranslation ?? this.hasManuallySelectedTranslation,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

// Provider
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('themeMode') ?? 0;
      final fontSize = prefs.getDouble('fontSize') ?? 18.0;
      final storedTranslation = prefs.getString('translation');
      final translation = normalizeTranslationCode(storedTranslation);
      final lastReadBook = prefs.getString('lastReadBook') ?? 'GEN';
      final lastReadChapter = prefs.getInt('lastReadChapter') ?? 1;
      final showPronunciation = prefs.getBool('showPronunciation') ?? false;
      final storedAppLanguage = prefs.getString('appLanguage');
      final appLanguage = normalizeAppLanguage(storedAppLanguage);
      final hasCompletedOnboarding =
          prefs.getBool('hasCompletedOnboarding') ?? false;
      final learningModeEnabled = prefs.getBool('learningModeEnabled') ?? false;
      final readerModeEnabled = prefs.getBool('readerModeEnabled') ?? false;
      final hebrewTextDisplay = HebrewTextDisplay.fromName(
        prefs.getString('hebrewTextDisplay'),
      );
      final showSenseUnits = prefs.getBool('showSenseUnits') ?? true;
      final hasSeenReadingHint = prefs.getBool('hasSeenReadingHint') ?? false;
      final hasManuallySelectedTranslation =
          prefs.getBool('hasManuallySelectedTranslation') ?? false;

      ThemeMode mode = ThemeMode.system;
      if (themeIndex == 1) mode = ThemeMode.light;
      if (themeIndex == 2) mode = ThemeMode.dark;

      if (storedTranslation != translation) {
        await prefs.setString('translation', translation);
      }
      if (storedAppLanguage != appLanguage) {
        await prefs.setString('appLanguage', appLanguage);
      }

      state = SettingsState(
        themeMode: mode,
        fontSize: fontSize,
        translation: translation,
        lastReadBook: lastReadBook,
        lastReadChapter: lastReadChapter,
        showPronunciation: showPronunciation,
        appLanguage: appLanguage,
        hasCompletedOnboarding: hasCompletedOnboarding,
        learningModeEnabled: learningModeEnabled,
        readerModeEnabled: readerModeEnabled,
        hebrewTextDisplay: hebrewTextDisplay,
        showSenseUnits: showSenseUnits,
        hasSeenReadingHint: hasSeenReadingHint,
        hasManuallySelectedTranslation: hasManuallySelectedTranslation,
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    int index = 0;
    if (mode == ThemeMode.light) index = 1;
    if (mode == ThemeMode.dark) index = 2;
    await prefs.setInt('themeMode', index);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
  }

  Future<void> setTranslation(String code) async {
    final normalized = normalizeTranslationCode(code);
    state = state.copyWith(
      translation: normalized,
      hasManuallySelectedTranslation: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation', normalized);
    await prefs.setBool('hasManuallySelectedTranslation', true);
  }

  Future<void> setTranslationFromSystem(String code) async {
    final normalized = normalizeTranslationCode(code);
    state = state.copyWith(translation: normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation', normalized);
  }

  Future<void> setLastRead(String bookId, int chapter) async {
    state = state.copyWith(lastReadBook: bookId, lastReadChapter: chapter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadBook', bookId);
    await prefs.setInt('lastReadChapter', chapter);
  }

  Future<void> setShowPronunciation(bool show) async {
    state = state.copyWith(showPronunciation: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPronunciation', show);
  }

  Future<void> setAppLanguageOnly(String language) async {
    final normalizedLanguage = normalizeAppLanguage(language);
    state = state.copyWith(appLanguage: normalizedLanguage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', normalizedLanguage);
  }

  Future<void> ensureEnabledTranslationSelection(Set<String> enabledIds) async {
    if (enabledIds.isEmpty) {
      return;
    }
    final normalizedEnabled = enabledIds
        .map((id) => normalizeTranslationCode(id))
        .toSet();
    final currentTranslation = normalizeTranslationCode(state.translation);
    if (normalizedEnabled.contains(currentTranslation)) {
      return;
    }

    final languageDefault = defaultTranslationForLanguage(state.appLanguage);
    final fallbackTranslation = normalizedEnabled.contains(languageDefault)
        ? languageDefault
        : (normalizedEnabled.contains('KJV') ? 'KJV' : normalizedEnabled.first);

    if (fallbackTranslation == currentTranslation) {
      return;
    }

    state = state.copyWith(translation: fallbackTranslation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation', fallbackTranslation);
  }

  Future<void> applyOnboardingLanguageDefault(String language) async {
    final normalizedLanguage = normalizeAppLanguage(language);
    if (state.hasManuallySelectedTranslation) {
      await setAppLanguageOnly(normalizedLanguage);
      return;
    }

    final translation = defaultTranslationForLanguage(normalizedLanguage);
    state = state.copyWith(
      appLanguage: normalizedLanguage,
      translation: translation,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', normalizedLanguage);
    await prefs.setString('translation', translation);
  }

  @Deprecated('Use setAppLanguageOnly + applyOnboardingLanguageDefault')
  Future<void> setAppLanguage(String language) async {
    await setAppLanguageOnly(language);
    await applyOnboardingLanguageDefault(language);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
  }

  Future<void> setLearningMode(bool enabled) async {
    state = state.copyWith(learningModeEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('learningModeEnabled', enabled);
  }

  Future<void> setReaderMode(bool enabled) async {
    state = state.copyWith(readerModeEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('readerModeEnabled', enabled);
  }

  Future<void> setHebrewTextDisplay(HebrewTextDisplay mode) async {
    state = state.copyWith(hebrewTextDisplay: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hebrewTextDisplay', mode.name);
  }

  Future<void> setShowSenseUnits(bool enabled) async {
    state = state.copyWith(showSenseUnits: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showSenseUnits', enabled);
  }

  Future<void> dismissReadingHint() async {
    state = state.copyWith(hasSeenReadingHint: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenReadingHint', true);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
