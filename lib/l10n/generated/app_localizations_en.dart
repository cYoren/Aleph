// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Original Bible';

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
      'Tap on any word to see its definition, pronunciation, and grammatical information. Toggle the pronunciation button to see how words are spoken.';

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
  String get learningModeEnglishOnlyNotice =>
      'Learning Mode currently supports English translations only.';

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
}
