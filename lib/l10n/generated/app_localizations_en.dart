// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aleph';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get selectLanguage => 'Select Your Language';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeDesc =>
      'Experience the Bible in its original languages with side-by-side translations.';

  @override
  String get onboardingHebrewTitle => 'Hebrew - Old Testament';

  @override
  String get onboardingHebrewDesc =>
      'The Old Testament was written in Hebrew, read from right to left. These texts were composed over 2,500 years ago and include the Torah, Psalms, and Prophets.';

  @override
  String get onboardingGreekTitle => 'Greek - New Testament';

  @override
  String get onboardingGreekDesc =>
      'The New Testament was written in Greek, read left to right. The Gospels and Epistles were composed between 50-100 AD.';

  @override
  String get onboardingTapTitle => 'Tap Any Word';

  @override
  String get onboardingTapDesc =>
      'Tap any word to see its definition, pronunciation, and grammatical information. Long-press a word for a quick meaning without leaving your place.';

  @override
  String get settings => 'Settings';

  @override
  String get translation => 'Translation';

  @override
  String get pronunciation => 'Show Pronunciation';

  @override
  String get pronunciationDesc => 'Display transliteration above words';

  @override
  String get fontSize => 'Font Size';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search in Bible text...';

  @override
  String get noResults => 'No results found';

  @override
  String get verseOfDay => 'Verse of the Day';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get home => 'Home';

  @override
  String get books => 'Books';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String get selectChapter => 'Select Chapter';

  @override
  String chapters(int count) {
    return '$count chapters';
  }

  @override
  String get translationNotAvailable => 'Translation not available';

  @override
  String get noLexiconEntry => 'No lexicon entry available';

  @override
  String get copyVerse => 'Copy verse';

  @override
  String get shareVerse => 'Share verse';

  @override
  String get verseCopied => 'Verse copied to clipboard';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String get noBookmarksDesc =>
      'Long-press a verse and tap the bookmark icon to save it here.';

  @override
  String get removeBookmarkConfirmation => 'Remove this bookmark?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# years ago',
      one: '# year ago',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# months ago',
      one: '# month ago',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days ago',
      one: '# day ago',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours ago',
      one: '# hour ago',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minutes ago',
      one: '# minute ago',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'Just now';

  @override
  String get quickMeaning => 'Quick Meaning';

  @override
  String get fullDefinition => 'Full Definition';

  @override
  String get pronunciationLabel => 'Pronunciation';

  @override
  String get hebrewOT => 'Hebrew • Old Testament';

  @override
  String get greekNT => 'Greek • New Testament';

  @override
  String get appResponsible => 'App Responsible';

  @override
  String get legalNameLabel => 'Legal Name';

  @override
  String get tradeNameLabel => 'Trade Name';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get error => 'Error';

  @override
  String get learningMode => 'Learning Mode';

  @override
  String get learningModeDesc =>
      'Passively learn original languages by seeing them in the text.';

  @override
  String get learningSectionTitle => 'Learning';

  @override
  String get loading => 'Loading...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Bible: $translation';
  }

  @override
  String get syntaxTreeTitle => 'Syntax Tree';

  @override
  String get viewSyntaxTree => 'View Syntax Tree';

  @override
  String get hebrewLabel => 'Hebrew';

  @override
  String get greekLabel => 'Greek';

  @override
  String get syntaxTreeTapHint =>
      'Tap any word node to see its full definition';

  @override
  String get noMorphologicalData =>
      'No morphological data available for this verse.';

  @override
  String get posVerb => 'Verb';

  @override
  String get posNoun => 'Noun';

  @override
  String get posAdjectiveShort => 'Adj.';

  @override
  String get posPronoun => 'Pronoun';

  @override
  String get posPrepositionShort => 'Prep.';

  @override
  String get posConjunctionShort => 'Conj.';

  @override
  String strongsHebrewLabel(String number) {
    return 'Hebrew $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Greek $number';
  }

  @override
  String get lemmaDictionaryForm => 'Lemma (Dictionary Form)';

  @override
  String get grammar => 'Grammar';

  @override
  String get topUsageByBook => 'Top Usage by Book';

  @override
  String get failedToLoadFrequencyData => 'Failed to load frequency data.';

  @override
  String get noUsageDataAvailable => 'No usage data available.';

  @override
  String get previousChapter => 'Previous Chapter';

  @override
  String get nextChapter => 'Next Chapter';

  @override
  String get createCinematicImage => 'Create Cinematic Image';

  @override
  String get srsQuestionPrompt => 'What does this word mean in this context?';

  @override
  String get revealAnswer => 'Reveal Answer';

  @override
  String get didntKnow => 'Didn\'t Know';

  @override
  String get knewIt => 'Knew It';

  @override
  String get srsPositiveFeedback => 'Great job! Word memory increased.';

  @override
  String get srsNegativeFeedback =>
      'Keep practicing. We\'ll show this word more often.';

  @override
  String get exportVerseTitle => 'Export Verse';

  @override
  String get shareImage => 'Share Image';

  @override
  String get backgroundTheme => 'Background Theme';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get failedToExportImage => 'Failed to export image.';

  @override
  String get exportUnavailableTitle => 'Export Unavailable';

  @override
  String get missingExportRouteData => 'Missing route data for export.';

  @override
  String get invalidExportRouteData => 'Invalid route data for export.';

  @override
  String get syntaxTreeUnavailableTitle => 'Syntax Tree Unavailable';

  @override
  String get missingSyntaxTreeRouteData =>
      'Missing route data for syntax tree.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Invalid route data for syntax tree.';

  @override
  String get noStrongsAvailable => 'No Strong\'s';

  @override
  String get wordStudyTitle => 'Word Study';

  @override
  String get seeAllUses => 'See all occurrences';

  @override
  String occurrencesTotal(int count) {
    return '$count occurrences in the Bible';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Showing the first $shown occurrences';
  }

  @override
  String get wordStudyUnavailableTitle => 'Word Study Unavailable';

  @override
  String get missingWordStudyRouteData =>
      'No word data was provided for this screen.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Grammatical sketch based on word-order heuristics — not verified syntax data.';

  @override
  String get readerMode => 'Reader mode';

  @override
  String get readerModeDesc =>
      'Gloss rare words inline while you read. Words you have mastered appear plain.';

  @override
  String get vocabularyTitle => 'Vocabulary';

  @override
  String get dueForReviewSection => 'Due for review';

  @override
  String get mostFrequentSection => 'Most frequent words';

  @override
  String vocabularyCoverage(String percent) {
    return 'These words cover $percent% of the text — learn them first.';
  }

  @override
  String get hebrewTextTitle => 'Hebrew text';

  @override
  String get hebrewTextDesc => 'Reading with fewer marks is a skill milestone';

  @override
  String get hebrewTextFull => 'Full (with cantillation)';

  @override
  String get hebrewTextNoCantillation => 'Vowels only';

  @override
  String get hebrewTextConsonantal => 'Consonants only';

  @override
  String get memorizationTitle => 'Memorization';

  @override
  String get memorizationEmpty =>
      'Nothing here yet. Add a psalm and start hiding words.';

  @override
  String get addPassageTitle => 'Add passage';

  @override
  String get addPassageButton => 'Add';

  @override
  String get selectBookLabel => 'Book';

  @override
  String get selectChapterLabel => 'Chapter';

  @override
  String masteryLabel(String percent) {
    return 'Mastery $percent%';
  }

  @override
  String get dueNowLabel => 'Due now';

  @override
  String get deletePassageTooltip => 'Remove passage';

  @override
  String get levelWarmUp => 'Warm-up';

  @override
  String get levelChallenge => 'Challenge';

  @override
  String get levelFirstLetters => 'First letters';

  @override
  String get tapHiddenWordHint => 'Tap a hidden word to reveal it';

  @override
  String get howDidItGo => 'How did it go?';

  @override
  String get struggledButton => 'Struggled';

  @override
  String get gotItButton => 'Got it';

  @override
  String nextReviewInDays(int count) {
    return 'Saved! Next review in $count days.';
  }

  @override
  String nextReviewInHours(int count) {
    return 'Saved! Next review in $count hours.';
  }

  @override
  String get missingMemorizationRouteData =>
      'No passage data was provided for this screen.';

  @override
  String get wordResultsSection => 'Words';

  @override
  String get verseResultsSection => 'Verses';

  @override
  String get crossReferencesTitle => 'Cross-references';

  @override
  String get noCrossReferences => 'No cross-references for this verse.';

  @override
  String get parsingQuizTitle => 'Parsing practice';

  @override
  String get whatFormIsThis => 'What form is this?';

  @override
  String get nextQuestion => 'Next';

  @override
  String quizScore(int score, int total) {
    return 'You got $score of $total';
  }

  @override
  String get practiceAgain => 'Practice again';

  @override
  String get doneButton => 'Done';

  @override
  String get syntaxSourceMacula =>
      'Syntax trees: MACULA Hebrew & Greek (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get readabilityTitle => 'What can I read?';

  @override
  String get readabilityAllBooks => 'Every book, most readable first';

  @override
  String get readabilityNoText => 'No text is loaded yet.';

  @override
  String get readabilityCanReadNow => 'You can read this now';

  @override
  String get readabilityClosest => 'Closest to readable';

  @override
  String get readabilityEmptyTitle =>
      'Start learning words to see this map fill in';

  @override
  String get readabilityEmptyBody =>
      'As you master vocabulary, each book shows how much of it you can already read. The most frequent words cover the most text, so progress here is quick at first.';

  @override
  String get openVocabulary => 'Open vocabulary';

  @override
  String get reciteAloud => 'Recite aloud';

  @override
  String get stopReciting => 'Stop reciting';

  @override
  String get recitationPreparing => 'Preparing…';

  @override
  String get recitationStop => 'Stop';

  @override
  String get hearItRead => 'Hear it read';

  @override
  String get phraseSpacingTitle => 'Phrase spacing';

  @override
  String get phraseSpacingDesc =>
      'Space the Hebrew at the Masoretic accents, so a verse reads in sense units instead of word by word.';

  @override
  String get recitationVoiceTitle => 'Recitation voice';

  @override
  String get recitationVoiceDesc =>
      'Read aloud by your device\'s speech voices: Modern Israeli for Hebrew, Modern Greek for Greek. These are living reading traditions, not reconstructed ancient pronunciation.';

  @override
  String get voiceMissing =>
      'Your device needs a Hebrew or Greek speech voice to read this aloud. Installing one takes a moment and only has to be done once.';

  @override
  String get voiceUnsupported => 'This device has no speech engine available.';

  @override
  String get voiceInstall => 'Install voice';

  @override
  String get voiceInstallUnavailable =>
      'This device has no voice installer to open.';

  @override
  String get recitationFailed => 'Recitation could not be started.';

  @override
  String readBook(String book) {
    return 'Read $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'You know $percent% of its vocabulary — about $count unfamiliar words per chapter.';
  }

  @override
  String recitationVerse(int number) {
    return 'Verse $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'No $tradition voice is installed on this device.';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count cross-references';
  }

  @override
  String get onboardingRecitationTitle => 'Hear It Recited';

  @override
  String get onboardingRecitationDesc =>
      'Press play to hear any chapter read aloud in Hebrew or Greek, by living voices rather than a reconstructed ancient pronunciation. Slow it right down from the speed control until your ear catches up.';

  @override
  String get readingHintTitle => 'Three ways in';

  @override
  String get readingHintBody =>
      'Tap a word for its full meaning. Long-press for a quick peek without losing your place. Press ▶ above to hear the chapter recited.';

  @override
  String get readingHintDismiss => 'Got it';

  @override
  String get explainTitle => 'Explain this passage';

  @override
  String get explainLoading => 'Reading the passage…';

  @override
  String get explainDisclaimer =>
      'Written by AI. It can be wrong — check it against the text.';

  @override
  String get explainSettingTitle => 'AI passage explanation';

  @override
  String get explainSettingDesc =>
      'Off by default. When on, the passage you are reading is sent over the internet to be explained. Everything else in this app works fully offline.';

  @override
  String get explainErrorOffline =>
      'No connection. This is the only feature that needs one.';

  @override
  String get explainErrorRateLimited =>
      'Too many requests just now. Try again in a moment.';

  @override
  String get explainErrorGeneric => 'The explanation could not be produced.';

  @override
  String get explainRetry => 'Try again';

  @override
  String get explainLowQuality =>
      'This answer looks off. Try again — and if it keeps happening, the model may need changing.';

  @override
  String explainFreeRemaining(int count) {
    return '$count free explanations left today';
  }

  @override
  String get explainLimitReached => 'You\'ve used today\'s free explanations.';

  @override
  String get explainUpgradeTitle => 'Unlimited, and a sharper model';

  @override
  String get explainDiagnosticsTitle => 'AI diagnostics';

  @override
  String get explainDiagnosticsDesc =>
      'Success rate and speed of the model answering your questions. Check here if answers seem worse than usual.';

  @override
  String get explainNoData => 'No explanations requested yet.';

  @override
  String get explainClearDiagnostics => 'Clear history';

  @override
  String get onboardingAiTitle => 'Ask about any passage';

  @override
  String get onboardingAiDesc =>
      'A tutor trained on your question: what does the Hebrew actually say, what does the Greek carry that English cannot. Tap the ✨ on any verse.';

  @override
  String get onboardingAiToggle => 'Enable the AI tutor';

  @override
  String get onboardingAiPrivacy =>
      'This is the only part of the app that uses the internet: the verse you ask about is sent to be explained. Everything else — the text, dictionaries, grammar, audio — works fully offline. You can change this any time in Settings.';

  @override
  String get reciteFromHere => 'Recite from here';

  @override
  String get searchEmptyTitle => 'Search the Bible';

  @override
  String get searchEmptyBody =>
      'Type any words from a verse to find it. Hebrew and Greek dictionary entries appear underneath the verses.';

  @override
  String get alphabetTitle => 'The alphabet';

  @override
  String get alphabetHebrewIntro =>
      'Hebrew reads from right to left. There are twenty-two letters and all of them are consonants — the dots and dashes written above and below them are the vowels. Take one letter at a time; there is no hurry.';

  @override
  String get alphabetGreekIntro =>
      'Greek reads from left to right and has both capital and small letters. Unlike Hebrew, its vowels are letters in their own right. Take one letter at a time; there is no hurry.';

  @override
  String get alphabetLettersSection => 'Letters';

  @override
  String get alphabetVowelsSection => 'Vowels';

  @override
  String get alphabetVowelsIntro =>
      'The vowels are marks written around a letter. They are shown here on bet (ב).';

  @override
  String get alphabetFinalForm => 'final';

  @override
  String get alphabetExampleLabel => 'In the Bible';

  @override
  String get wordConnections => 'Word connections';

  @override
  String get wordConnectionsDesc =>
      'Draw lines between the other occurrences of a word you tap. Off by default, because the lines cross the text you are reading.';

  @override
  String get memorizationSubtitle =>
      'Hide words in a passage you already read comfortably.';

  @override
  String get onboardingTraditionTitle => 'Which scriptures are you reading?';

  @override
  String get onboardingTraditionDesc =>
      'This decides how the books are ordered and what they are called. Nothing is hidden either way, and you can change it in Settings.';

  @override
  String get traditionChristian => 'Old and New Testament';

  @override
  String get traditionChristianDesc =>
      'The Christian order, from Genesis through Revelation.';

  @override
  String get traditionJewish => 'Tanakh';

  @override
  String get traditionJewishDesc =>
      'Torah, Nevi\'im and Ketuvim, in the traditional Jewish order.';

  @override
  String get tanakhTorah => 'Torah';

  @override
  String get tanakhNeviim => 'Nevi\'im — Prophets';

  @override
  String get tanakhKetuvim => 'Ketuvim — Writings';

  @override
  String get hebrewBibleLabel => 'Hebrew Bible';

  @override
  String get traditionSettingTitle => 'Scriptures';

  @override
  String get backToPrevious => 'Back to where you were';

  @override
  String get copyOriginal => 'Copy original text';

  @override
  String get copyBoth => 'Copy original and translation';

  @override
  String searchKeepTyping(int count) {
    return 'Type at least $count letters to search.';
  }

  @override
  String verseResultsShowing(int shown, int total) {
    return 'Verses — showing $shown of $total';
  }

  @override
  String get searchFailedBody =>
      'The search could not be completed. Try again.';

  @override
  String get errorGenericBody =>
      'Something went wrong loading this. Try again.';

  @override
  String get verseOfDayUnavailable => 'Today\'s verse could not be loaded.';

  @override
  String get wordGestureHint =>
      'Tap for the full entry, press and hold for the meaning';

  @override
  String masteryPercent(int percent) {
    return '$percent% learned';
  }

  @override
  String get readingSectionTitle => 'Reading';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get traditionSettingDesc => 'Sets how the books are named and ordered';

  @override
  String get fontSizeSample => 'The size of the text you read';

  @override
  String get recitationVoiceUnavailable =>
      'This device has no voice download screen.';

  @override
  String get recitationPause => 'Pause';

  @override
  String get recitationResume => 'Resume';

  @override
  String get recitationPreviousVerse => 'Previous verse';

  @override
  String get recitationNextVerse => 'Next verse';

  @override
  String recitationPausedAtVerse(int number) {
    return 'Paused at verse $number';
  }

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get undo => 'Undo';

  @override
  String get bookFilterHint => 'Find a book';

  @override
  String get clearFilter => 'Clear';

  @override
  String get databasePreparingTitle => 'Preparing the library';

  @override
  String get databasePreparingBody =>
      'Copying the text, dictionaries and grammar to this device. This happens once, and everything works offline afterwards.';

  @override
  String get databasePrepareFailed =>
      'The library could not be prepared. Check that there is enough free space and try again.';

  @override
  String get aboutSourcesTitle => 'Sources and credits';

  @override
  String get aboutSourcesDesc =>
      'Where the text, dictionaries and typefaces came from';

  @override
  String get aboutSourcesSectionTitle => 'What is in this app';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutLicensesTitle => 'Open source licences';

  @override
  String get aboutLicensesDesc => 'The software libraries this app is built on';

  @override
  String get sourceOriginalTextTitle => 'Hebrew and Greek text';

  @override
  String get sourceOriginalTextBody =>
      'Westminster Leningrad Codex (Hebrew Bible) and the SBL Greek New Testament, both in the public domain or freely licensed.';

  @override
  String get sourceTranslationsTitle => 'Translations';

  @override
  String get sourceTranslationsBody =>
      'Public-domain and freely licensed translations, including the King James Version. Each translation keeps its own provenance in the database.';

  @override
  String get sourceLexiconTitle => 'Dictionaries and morphology';

  @override
  String get sourceLexiconBody =>
      'Strong\'s Hebrew and Greek dictionaries, with morphological parsing from the OpenScriptures and MorphGNT projects.';

  @override
  String get sourceSyntaxTitle => 'Sentence structure';

  @override
  String get sourceSyntaxBody =>
      'Syntax trees from the MACULA Hebrew and Greek datasets by Clear Bible, used under CC BY 4.0.';

  @override
  String get sourceFontsTitle => 'Typefaces';

  @override
  String get sourceFontsBody =>
      'Ezra SIL for Hebrew and Gentium for Greek and Latin, both from SIL International under the SIL Open Font License.';

  @override
  String get onboardingHebrewExampleGloss =>
      '\"In the beginning God created…\"';

  @override
  String get onboardingGreekExampleGloss =>
      '\"In the beginning was the Word…\"';
}
