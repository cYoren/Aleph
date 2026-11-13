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
      'Chapters are read by voices built into the app — no download and no internet needed: Modern Greek for the New Testament. Hebrew is read by your device\'s own voice, because no Hebrew voice we are allowed to bundle exists yet. These are living reading traditions, not reconstructed ancient pronunciation.';

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
      'Press play to hear any chapter read aloud. The New Testament is read by a Modern Greek voice built into the app, so it works offline on a fresh install. Hebrew uses your device\'s voice. Slow it right down from the speed control until your ear catches up.';

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
  String get reviewReminderSetting => 'Daily review reminder';

  @override
  String get reviewReminderSettingSubtitle =>
      'An evening nudge when words are due';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words are ready for review',
      one: '1 word is ready for review',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody =>
      'Five minutes now keeps them from slipping away.';

  @override
  String get reminderReadTitle => 'Your verse for today is waiting';

  @override
  String get reminderReadBody =>
      'Read one verse in Hebrew or Greek before the day ends.';

  @override
  String get pathTitle => 'Book paths';

  @override
  String get pathHomeStart =>
      'Pick a book and learn exactly the words it needs';

  @override
  String get pathChooseBook => 'Choose a book to read in the original';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words to read 80% of it',
      one: '1 word to read 80% of it',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return 'You can read $percent% of $book';
  }

  @override
  String pathLearning(int percent) {
    return '$percent% counting the words you are learning';
  }

  @override
  String get pathGoalReached =>
      'You can read most of this book. Open it and enjoy!';

  @override
  String get pathLearnNext => 'Learn the next words';

  @override
  String get pathWordsInBook => 'Words in this book, most common first';

  @override
  String get pathChangeBook => 'Change book';

  @override
  String get pathShare => 'Share progress';

  @override
  String shareCardHebrew(int percent, String book) {
    return 'I\'ve learned $percent% of the words in $book, in Hebrew';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return 'I\'ve learned $percent% of the words in $book, in Greek';
  }

  @override
  String get shareCardFooter => 'Learning with Aleph';

  @override
  String get pathAllLearned =>
      'You have started every word in this book. Keep reviewing!';

  @override
  String get dailySessionStart => 'Today\'s 5 minutes';

  @override
  String get dailySessionDone => 'Done for today. See you tomorrow!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get nameTitle => 'What does your name mean?';

  @override
  String get nameHint => 'Type your name';

  @override
  String nameMeans(String name, String meaning) {
    return '$name means “$meaning”';
  }

  @override
  String nameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Appears $count times in the Bible',
      one: 'Appears once in the Bible',
    );
    return '$_temp0';
  }

  @override
  String get nameNotFound => 'Not on our list yet. Try another spelling.';

  @override
  String get nameShare => 'Share';

  @override
  String get usageSharingTitle => 'Share anonymous usage counts';

  @override
  String get usageSharingSubtitle =>
      'Which features get used. Never what you read, and nothing that identifies you.';

  @override
  String get supportTitle => 'Support Aleph';

  @override
  String get supportBody =>
      'Aleph is one person\'s work: no ads, no subscription, no tracking. A one-time tip keeps the text, the voices and the updates coming.';

  @override
  String get supportNote =>
      'Tips unlock nothing. Every word of Aleph is already yours.';

  @override
  String get supportTierSmall => 'A small tip';

  @override
  String get supportTierMedium => 'A generous tip';

  @override
  String get supportTierLarge => 'A big tip';

  @override
  String get supportThanks => 'Thank you. That genuinely helps.';

  @override
  String get supportUnavailable => 'Tips are not available right now.';

  @override
  String get supportClose => 'Not now';

  @override
  String get supportTerms => 'Terms';

  @override
  String get supportPrivacy => 'Privacy';

  @override
  String get morphHebrew => 'Hebrew';

  @override
  String get morphAramaic => 'Aramaic';

  @override
  String get morphAdjective => 'Adjective';

  @override
  String get morphConjunction => 'Conjunction';

  @override
  String get morphAdverb => 'Adverb';

  @override
  String get morphNoun => 'Noun';

  @override
  String get morphPronoun => 'Pronoun';

  @override
  String get morphPreposition => 'Preposition';

  @override
  String get morphSuffix => 'Suffix';

  @override
  String get morphParticle => 'Particle';

  @override
  String get morphVerb => 'Verb';

  @override
  String get morphArticle => 'Article';

  @override
  String get morphInterjection => 'Interjection';

  @override
  String get morphCommon => 'common';

  @override
  String get morphProper => 'proper';

  @override
  String get morphGentilic => 'gentilic';

  @override
  String get morphMasculine => 'masculine';

  @override
  String get morphFeminine => 'feminine';

  @override
  String get morphBothGenders => 'both genders';

  @override
  String get morphNeuter => 'neuter';

  @override
  String get morphSingular => 'singular';

  @override
  String get morphPlural => 'plural';

  @override
  String get morphDual => 'dual';

  @override
  String get morphAbsolute => 'absolute';

  @override
  String get morphConstruct => 'construct';

  @override
  String get morphDetermined => 'determined';

  @override
  String get morphFirstPerson => '1st person';

  @override
  String get morphSecondPerson => '2nd person';

  @override
  String get morphThirdPerson => '3rd person';

  @override
  String get morphPerfect => 'Perfect';

  @override
  String get morphSequentialPerfect => 'Sequential Perfect';

  @override
  String get morphImperfect => 'Imperfect';

  @override
  String get morphSequentialImperfect => 'Sequential Imperfect';

  @override
  String get morphCohortative => 'Cohortative';

  @override
  String get morphJussive => 'Jussive';

  @override
  String get morphImperative => 'Imperative';

  @override
  String get morphParticipleActive => 'Participle Active';

  @override
  String get morphParticiplePassive => 'Participle Passive';

  @override
  String get morphInfinitiveAbsolute => 'Infinitive Absolute';

  @override
  String get morphInfinitiveConstruct => 'Infinitive Construct';

  @override
  String get morphCardinalNumber => 'cardinal number';

  @override
  String get morphOrdinalNumber => 'ordinal number';

  @override
  String get morphDemonstrative => 'demonstrative';

  @override
  String get morphIndefinite => 'indefinite';

  @override
  String get morphInterrogative => 'interrogative';

  @override
  String get morphPersonal => 'personal';

  @override
  String get morphRelative => 'relative';

  @override
  String get morphReciprocal => 'reciprocal';

  @override
  String get morphReflexive => 'reflexive';

  @override
  String get morphPossessive => 'possessive';

  @override
  String get morphCorrelative => 'correlative';

  @override
  String get morphDirectional => 'directional';

  @override
  String get morphParagogicHe => 'paragogic he';

  @override
  String get morphParagogicNun => 'paragogic nun';

  @override
  String get morphPronominal => 'pronominal';

  @override
  String get morphPresent => 'Present';

  @override
  String get morphFuture => 'Future';

  @override
  String get morphAorist => 'Aorist';

  @override
  String get morphPluperfect => 'Pluperfect';

  @override
  String get morphNoTense => 'No tense';

  @override
  String get morphActive => 'Active';

  @override
  String get morphMiddle => 'Middle';

  @override
  String get morphPassive => 'Passive';

  @override
  String get morphMiddlePassive => 'Middle/Passive';

  @override
  String get morphMiddleDeponent => 'Middle Deponent';

  @override
  String get morphPassiveDeponent => 'Passive Deponent';

  @override
  String get morphMiddlePassiveDeponent => 'Middle/Passive Deponent';

  @override
  String get morphIndicative => 'Indicative';

  @override
  String get morphSubjunctive => 'Subjunctive';

  @override
  String get morphOptative => 'Optative';

  @override
  String get morphInfinitive => 'Infinitive';

  @override
  String get morphParticiple => 'Participle';

  @override
  String get morphNominative => 'Nominative';

  @override
  String get morphGenitive => 'Genitive';

  @override
  String get morphDative => 'Dative';

  @override
  String get morphAccusative => 'Accusative';

  @override
  String get morphVocative => 'Vocative';

  @override
  String get contentSourceNote =>
      'Shown in English; no translation is available yet.';

  @override
  String get recitationVoiceHebrewGap =>
      'Hebrew uses your device\'s speech voice. A bundled Hebrew voice has not yet been validated for Aleph.';

  @override
  String get contentLoadError => 'Couldn\'t load this content. Try again.';

  @override
  String get diagnosticsSuccess => 'Success';

  @override
  String get diagnosticsMedian => 'Median time';

  @override
  String get diagnosticsCalls => 'Requests';

  @override
  String get diagnosticsPoorAnswers => 'Poor answers';

  @override
  String get diagnosticsErrors => 'Errors';

  @override
  String get diagnosticsLastProblem => 'Last problem';

  @override
  String get diagnosticsInUse => 'In use';

  @override
  String get diagnosticsNotUsed => 'Not used yet';

  @override
  String get diagnosticsTooEarly => 'Too early to tell';

  @override
  String get diagnosticsEarlyProblems => 'Too early to tell. Some problems.';

  @override
  String get diagnosticsFailing => 'Failing. Switch model.';

  @override
  String get diagnosticsUnreliable => 'Unreliable. Consider switching.';

  @override
  String get diagnosticsSlow => 'Very slow. Consider switching.';

  @override
  String get diagnosticsMostlyGood => 'Mostly fine. Some poor answers.';

  @override
  String get diagnosticsHealthy => 'Working well';

  @override
  String get sensesLabel => 'Senses';

  @override
  String get sensesUnavailable =>
      'This entry has no numbered senses in the dictionary.';

  @override
  String get rootLabel => 'Root';

  @override
  String get rootWordsTitle => 'Words on this root';

  @override
  String rootWordCount(int count) {
    return '$count words';
  }

  @override
  String get formsInTextLabel => 'Forms in the text';

  @override
  String get formsInTextNote =>
      'Only the forms that actually occur in the text.';

  @override
  String showAllCount(int count) {
    return 'Show all $count';
  }

  @override
  String get markAsKnown => 'Mark as known';

  @override
  String get markedAsKnown => 'Known';

  @override
  String get markAsKnownDone =>
      'Marked as known. It stops being glossed in reading mode.';

  @override
  String get transliterationLabel => 'Transliteration';

  @override
  String get refersToLabel => 'Refers to';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get firstStepsHomeTitle => 'Start here';

  @override
  String get firstStepsHomeDesc => 'Three letters, one verse, five words.';

  @override
  String get firstStepsTitle => 'Your first verse';

  @override
  String get firstStepsLettersTitle => 'Three letters';

  @override
  String get firstStepsLettersDesc =>
      'These three are enough to read a real word. Tap a letter to hear it.';

  @override
  String get firstStepsWordTitle => 'One word';

  @override
  String get firstStepsWordDesc =>
      'The letters you just met, inside a word from the Bible.';

  @override
  String get firstStepsVerseTitle => 'One verse';

  @override
  String get firstStepsVerseDesc =>
      'Every word carries its sound and its meaning. Nothing here is a test.';

  @override
  String get firstStepsVerseHint =>
      'Tap any word for its full dictionary entry.';

  @override
  String get firstStepsReviewTitle => 'Five words';

  @override
  String get firstStepsReviewDesc =>
      'The five words worth keeping from this verse. One pass, then you are done.';

  @override
  String get firstStepsReviewButton => 'Review these five';

  @override
  String get firstStepsStart => 'Start';

  @override
  String get firstStepsContinue => 'Continue';

  @override
  String get firstStepsRestart => 'Start again';

  @override
  String firstVerseInMinutes(int minutes) {
    return 'Your first verse in $minutes minutes.';
  }

  @override
  String get firstVerseUnderMinute => 'Your first verse in under a minute.';

  @override
  String get firstStepsDoneTitle => 'That is the way in';

  @override
  String get firstStepsDoneDesc =>
      'Letters, a word, a verse, five words you will meet again. The reader is open to you now.';

  @override
  String get firstStepsDoneReader => 'Open the reader';

  @override
  String get verseLabel => 'Verse';
}
