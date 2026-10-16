import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/utils/hebrew_display.dart';
import '../../shared/utils/reading_tradition.dart';

// Language to default translation mapping, unless the reader chose an edition.
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
  final normalized = (languageCode ?? '')
      .trim()
      .toLowerCase()
      .split(RegExp('[-_]'))
      .first;
  if (_supportedAppLanguages.contains(normalized)) {
    return normalized;
  }
  return 'en';
}

String normalizeTranslationCode(String? code, {String languageCode = 'en'}) {
  final normalized = (code ?? '').trim().toUpperCase();
  if (_supportedTranslationIds.contains(normalized)) {
    return normalized;
  }
  return languageToTranslation[normalizeAppLanguage(languageCode)] ?? 'KJV';
}

/// Uses the first supported device language on a new installation.
String appLanguageForDevice(Iterable<Locale> locales) {
  for (final locale in locales) {
    final language = locale.languageCode.toLowerCase();
    if (_supportedAppLanguages.contains(language)) return language;
  }
  return 'en';
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

  /// Latin transliteration above each word. **On by default**: a reader who
  /// cannot yet sound out the alphabet has no way in without it, and someone
  /// fluent enough to be annoyed by it can find the toggle in the reader.
  final bool showPronunciation;
  final String appLanguage;
  final bool hasCompletedOnboarding;
  final bool learningModeEnabled;
  final bool readerModeEnabled;
  final HebrewTextDisplay hebrewTextDisplay;

  /// Space the Hebrew text at the Masoretic disjunctive accents, so a verse
  /// reads as phrases rather than a flat row of words.
  final bool showSenseUnits;

  /// Which scriptures the reader came for, and how they are arranged and
  /// named. Chosen once in onboarding, changeable in Settings.
  final ReadingTradition tradition;

  /// Draw curved connectors between every other occurrence of the word you
  /// tapped. **Off by default**: the lines cross the text you are trying to
  /// read, which is the opposite of a calm page. The same information is in
  /// the definition sheet's usage graph and the concordance.
  final bool showWordConnections;

  /// Whether the reader has dismissed the one-time hint about tap /
  /// long-press / recite. Onboarding teaches the same affordances, but a
  /// user who taps Skip there should still learn them somewhere.
  final bool hasSeenReadingHint;

  /// AI passage explanation. Offered during onboarding and **on by default**
  /// once accepted there. This is the only feature in the app that sends
  /// anything over the network — the passage text leaves the device when it is
  /// on — so onboarding states that plainly and the switch stays reachable in
  /// Settings.
  final bool aiExplainEnabled;

  /// True once the reader has bought the unlimited, better-model tier.
  ///
  /// Currently a local flag: there is no purchase flow yet, so nothing sets it
  /// outside of Settings. Wiring it to a real StoreKit / Play Billing
  /// entitlement is the remaining work before charging anyone.
  final bool aiProUnlocked;

  /// Free-tier usage, reset each day.
  final int aiExplainUsedToday;

  /// Day the counter above belongs to, as yyyy-mm-dd.
  final String aiExplainUsageDay;

  final bool hasManuallySelectedTranslation;
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 18.0,
    this.translation = 'KJV',
    this.lastReadBook = 'GEN',
    this.lastReadChapter = 1,
    this.showPronunciation = true,
    this.appLanguage = 'en',
    this.hasCompletedOnboarding = false,
    this.learningModeEnabled = false,
    this.readerModeEnabled = false,
    this.hebrewTextDisplay = HebrewTextDisplay.full,
    this.showSenseUnits = true,
    this.tradition = ReadingTradition.christian,
    this.showWordConnections = false,
    this.hasSeenReadingHint = false,
    this.aiExplainEnabled = true,
    this.aiProUnlocked = false,
    this.aiExplainUsedToday = 0,
    this.aiExplainUsageDay = '',
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
    ReadingTradition? tradition,
    bool? showWordConnections,
    bool? hasSeenReadingHint,
    bool? aiExplainEnabled,
    bool? aiProUnlocked,
    int? aiExplainUsedToday,
    String? aiExplainUsageDay,
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
      tradition: tradition ?? this.tradition,
      showWordConnections: showWordConnections ?? this.showWordConnections,
      hasSeenReadingHint: hasSeenReadingHint ?? this.hasSeenReadingHint,
      aiExplainEnabled: aiExplainEnabled ?? this.aiExplainEnabled,
      aiProUnlocked: aiProUnlocked ?? this.aiProUnlocked,
      aiExplainUsedToday: aiExplainUsedToday ?? this.aiExplainUsedToday,
      aiExplainUsageDay: aiExplainUsageDay ?? this.aiExplainUsageDay,
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
      final lastReadBook = prefs.getString('lastReadBook') ?? 'GEN';
      final lastReadChapter = prefs.getInt('lastReadChapter') ?? 1;
      final showPronunciation = prefs.getBool('showPronunciation') ?? true;
      final storedAppLanguage = prefs.getString('appLanguage');
      final appLanguage = storedAppLanguage == null
          ? appLanguageForDevice(
              WidgetsBinding.instance.platformDispatcher.locales,
            )
          : normalizeAppLanguage(storedAppLanguage);
      final hasCompletedOnboarding =
          prefs.getBool('hasCompletedOnboarding') ?? false;
      final learningModeEnabled = prefs.getBool('learningModeEnabled') ?? false;
      final readerModeEnabled = prefs.getBool('readerModeEnabled') ?? false;
      final hebrewTextDisplay = HebrewTextDisplay.fromName(
        prefs.getString('hebrewTextDisplay'),
      );
      final showSenseUnits = prefs.getBool('showSenseUnits') ?? true;
      final tradition = ReadingTradition.fromName(prefs.getString('tradition'));
      final showWordConnections = prefs.getBool('showWordConnections') ?? false;
      final hasSeenReadingHint = prefs.getBool('hasSeenReadingHint') ?? false;
      final aiExplainEnabled = prefs.getBool('aiExplainEnabled') ?? true;
      final aiProUnlocked = prefs.getBool('aiProUnlocked') ?? false;
      final aiExplainUsedToday = prefs.getInt('aiExplainUsedToday') ?? 0;
      final aiExplainUsageDay = prefs.getString('aiExplainUsageDay') ?? '';
      final hasManuallySelectedTranslation =
          prefs.getBool('hasManuallySelectedTranslation') ?? false;

      ThemeMode mode = ThemeMode.system;
      if (themeIndex == 1) mode = ThemeMode.light;
      if (themeIndex == 2) mode = ThemeMode.dark;

      // Anyone who never picked a translation by hand reads the Bible of their
      // own language. Earlier builds only applied this during onboarding, so
      // installs that predate it — or that changed language in Settings — were
      // left reading the KJV in a Portuguese interface.
      final translation = hasManuallySelectedTranslation
          ? normalizeTranslationCode(
              storedTranslation,
              languageCode: appLanguage,
            )
          : defaultTranslationForLanguage(appLanguage);

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
        tradition: tradition,
        showWordConnections: showWordConnections,
        hasSeenReadingHint: hasSeenReadingHint,
        aiExplainEnabled: aiExplainEnabled,
        aiProUnlocked: aiProUnlocked,
        aiExplainUsedToday: aiExplainUsedToday,
        aiExplainUsageDay: aiExplainUsageDay,
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

  /// Points the reader at the Bible of [language], unless they have chosen a
  /// translation by hand — in which case that choice wins and only the
  /// interface language moves.
  ///
  /// Called from onboarding *and* from Settings: picking Português there and
  /// still getting the King James was the single loudest complaint about the
  /// language switch.
  Future<void> applyLanguageDefaultTranslation(String language) async {
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

  /// Switches the interface language and, with it, the Bible the reader sees.
  Future<void> setAppLanguage(String language) async {
    await setAppLanguageOnly(language);
    await applyLanguageDefaultTranslation(language);
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

  Future<void> setTradition(ReadingTradition tradition) async {
    state = state.copyWith(tradition: tradition);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tradition', tradition.name);
  }

  Future<void> setShowWordConnections(bool enabled) async {
    state = state.copyWith(showWordConnections: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showWordConnections', enabled);
  }

  Future<void> setAiExplainEnabled(bool enabled) async {
    state = state.copyWith(aiExplainEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiExplainEnabled', enabled);
  }

  Future<void> setAiProUnlocked(bool unlocked) async {
    state = state.copyWith(aiProUnlocked: unlocked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiProUnlocked', unlocked);
  }

  /// Records one free-tier explanation, rolling the counter over at midnight.
  Future<void> recordAiExplainUse() async {
    final today = _todayKey();
    final isNewDay = state.aiExplainUsageDay != today;
    final used = isNewDay ? 1 : state.aiExplainUsedToday + 1;

    state = state.copyWith(aiExplainUsedToday: used, aiExplainUsageDay: today);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aiExplainUsedToday', used);
    await prefs.setString('aiExplainUsageDay', today);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
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
