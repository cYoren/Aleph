import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Aleph'**
  String get appTitle;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectLanguage;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Experience the Bible in its original languages with side-by-side translations.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingHebrewTitle.
  ///
  /// In en, this message translates to:
  /// **'Hebrew - Old Testament'**
  String get onboardingHebrewTitle;

  /// No description provided for @onboardingHebrewDesc.
  ///
  /// In en, this message translates to:
  /// **'The Old Testament was written in Hebrew, read from right to left. These texts were composed over 2,500 years ago and include the Torah, Psalms, and Prophets.'**
  String get onboardingHebrewDesc;

  /// No description provided for @onboardingGreekTitle.
  ///
  /// In en, this message translates to:
  /// **'Greek - New Testament'**
  String get onboardingGreekTitle;

  /// No description provided for @onboardingGreekDesc.
  ///
  /// In en, this message translates to:
  /// **'The New Testament was written in Greek, read left to right. The Gospels and Epistles were composed between 50-100 AD.'**
  String get onboardingGreekDesc;

  /// No description provided for @onboardingTapTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap Any Word'**
  String get onboardingTapTitle;

  /// No description provided for @onboardingTapDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap any word to see its definition, pronunciation, and grammatical information. Long-press a word for a quick meaning without leaving your place.'**
  String get onboardingTapDesc;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Show Pronunciation'**
  String get pronunciation;

  /// No description provided for @pronunciationDesc.
  ///
  /// In en, this message translates to:
  /// **'Display transliteration above words'**
  String get pronunciationDesc;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in Bible text...'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @verseOfDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfDay;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @selectChapter.
  ///
  /// In en, this message translates to:
  /// **'Select Chapter'**
  String get selectChapter;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chapters(int count);

  /// No description provided for @translationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Translation not available'**
  String get translationNotAvailable;

  /// No description provided for @noLexiconEntry.
  ///
  /// In en, this message translates to:
  /// **'No lexicon entry available'**
  String get noLexiconEntry;

  /// No description provided for @copyVerse.
  ///
  /// In en, this message translates to:
  /// **'Copy verse'**
  String get copyVerse;

  /// No description provided for @shareVerse.
  ///
  /// In en, this message translates to:
  /// **'Share verse'**
  String get shareVerse;

  /// No description provided for @verseCopied.
  ///
  /// In en, this message translates to:
  /// **'Verse copied to clipboard'**
  String get verseCopied;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press a verse and tap the bookmark icon to save it here.'**
  String get noBookmarksDesc;

  /// No description provided for @removeBookmarkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove this bookmark?'**
  String get removeBookmarkConfirmation;

  /// No description provided for @bookmarkTimeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# year ago} other {# years ago}}'**
  String bookmarkTimeYearsAgo(int count);

  /// No description provided for @bookmarkTimeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# month ago} other {# months ago}}'**
  String bookmarkTimeMonthsAgo(int count);

  /// No description provided for @bookmarkTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# day ago} other {# days ago}}'**
  String bookmarkTimeDaysAgo(int count);

  /// No description provided for @bookmarkTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# hour ago} other {# hours ago}}'**
  String bookmarkTimeHoursAgo(int count);

  /// No description provided for @bookmarkTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# minute ago} other {# minutes ago}}'**
  String bookmarkTimeMinutesAgo(int count);

  /// No description provided for @bookmarkTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get bookmarkTimeJustNow;

  /// No description provided for @quickMeaning.
  ///
  /// In en, this message translates to:
  /// **'Quick Meaning'**
  String get quickMeaning;

  /// No description provided for @fullDefinition.
  ///
  /// In en, this message translates to:
  /// **'Full Definition'**
  String get fullDefinition;

  /// No description provided for @pronunciationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pronunciationLabel;

  /// No description provided for @hebrewOT.
  ///
  /// In en, this message translates to:
  /// **'Hebrew • Old Testament'**
  String get hebrewOT;

  /// No description provided for @greekNT.
  ///
  /// In en, this message translates to:
  /// **'Greek • New Testament'**
  String get greekNT;

  /// No description provided for @appResponsible.
  ///
  /// In en, this message translates to:
  /// **'App Responsible'**
  String get appResponsible;

  /// No description provided for @legalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal Name'**
  String get legalNameLabel;

  /// No description provided for @tradeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trade Name'**
  String get tradeNameLabel;

  /// No description provided for @cnpjLabel.
  ///
  /// In en, this message translates to:
  /// **'CNPJ'**
  String get cnpjLabel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @learningMode.
  ///
  /// In en, this message translates to:
  /// **'Learning Mode'**
  String get learningMode;

  /// No description provided for @learningModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Passively learn original languages by seeing them in the text.'**
  String get learningModeDesc;

  /// No description provided for @learningSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningSectionTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @onboardingBibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bible: {translation}'**
  String onboardingBibleLabel(String translation);

  /// No description provided for @syntaxTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Syntax Tree'**
  String get syntaxTreeTitle;

  /// No description provided for @viewSyntaxTree.
  ///
  /// In en, this message translates to:
  /// **'View Syntax Tree'**
  String get viewSyntaxTree;

  /// No description provided for @hebrewLabel.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrewLabel;

  /// No description provided for @greekLabel.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get greekLabel;

  /// No description provided for @syntaxTreeTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any word node to see its full definition'**
  String get syntaxTreeTapHint;

  /// No description provided for @noMorphologicalData.
  ///
  /// In en, this message translates to:
  /// **'No morphological data available for this verse.'**
  String get noMorphologicalData;

  /// No description provided for @posVerb.
  ///
  /// In en, this message translates to:
  /// **'Verb'**
  String get posVerb;

  /// No description provided for @posNoun.
  ///
  /// In en, this message translates to:
  /// **'Noun'**
  String get posNoun;

  /// No description provided for @posAdjectiveShort.
  ///
  /// In en, this message translates to:
  /// **'Adj.'**
  String get posAdjectiveShort;

  /// No description provided for @posPronoun.
  ///
  /// In en, this message translates to:
  /// **'Pronoun'**
  String get posPronoun;

  /// No description provided for @posPrepositionShort.
  ///
  /// In en, this message translates to:
  /// **'Prep.'**
  String get posPrepositionShort;

  /// No description provided for @posConjunctionShort.
  ///
  /// In en, this message translates to:
  /// **'Conj.'**
  String get posConjunctionShort;

  /// No description provided for @strongsHebrewLabel.
  ///
  /// In en, this message translates to:
  /// **'Hebrew {number}'**
  String strongsHebrewLabel(String number);

  /// No description provided for @strongsGreekLabel.
  ///
  /// In en, this message translates to:
  /// **'Greek {number}'**
  String strongsGreekLabel(String number);

  /// No description provided for @lemmaDictionaryForm.
  ///
  /// In en, this message translates to:
  /// **'Lemma (Dictionary Form)'**
  String get lemmaDictionaryForm;

  /// No description provided for @grammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammar;

  /// No description provided for @topUsageByBook.
  ///
  /// In en, this message translates to:
  /// **'Top Usage by Book'**
  String get topUsageByBook;

  /// No description provided for @failedToLoadFrequencyData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load frequency data.'**
  String get failedToLoadFrequencyData;

  /// No description provided for @noUsageDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No usage data available.'**
  String get noUsageDataAvailable;

  /// No description provided for @previousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter'**
  String get previousChapter;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get nextChapter;

  /// No description provided for @createCinematicImage.
  ///
  /// In en, this message translates to:
  /// **'Create Cinematic Image'**
  String get createCinematicImage;

  /// No description provided for @srsQuestionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What does this word mean in this context?'**
  String get srsQuestionPrompt;

  /// No description provided for @revealAnswer.
  ///
  /// In en, this message translates to:
  /// **'Reveal Answer'**
  String get revealAnswer;

  /// No description provided for @didntKnow.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t Know'**
  String get didntKnow;

  /// No description provided for @knewIt.
  ///
  /// In en, this message translates to:
  /// **'Knew It'**
  String get knewIt;

  /// No description provided for @srsPositiveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Great job! Word memory increased.'**
  String get srsPositiveFeedback;

  /// No description provided for @srsNegativeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing. We\'ll show this word more often.'**
  String get srsNegativeFeedback;

  /// No description provided for @exportVerseTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Verse'**
  String get exportVerseTitle;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get shareImage;

  /// No description provided for @backgroundTheme.
  ///
  /// In en, this message translates to:
  /// **'Background Theme'**
  String get backgroundTheme;

  /// No description provided for @aspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get aspectRatio;

  /// No description provided for @failedToExportImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to export image.'**
  String get failedToExportImage;

  /// No description provided for @exportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Unavailable'**
  String get exportUnavailableTitle;

  /// No description provided for @missingExportRouteData.
  ///
  /// In en, this message translates to:
  /// **'Missing route data for export.'**
  String get missingExportRouteData;

  /// No description provided for @invalidExportRouteData.
  ///
  /// In en, this message translates to:
  /// **'Invalid route data for export.'**
  String get invalidExportRouteData;

  /// No description provided for @syntaxTreeUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Syntax Tree Unavailable'**
  String get syntaxTreeUnavailableTitle;

  /// No description provided for @missingSyntaxTreeRouteData.
  ///
  /// In en, this message translates to:
  /// **'Missing route data for syntax tree.'**
  String get missingSyntaxTreeRouteData;

  /// No description provided for @invalidSyntaxTreeRouteData.
  ///
  /// In en, this message translates to:
  /// **'Invalid route data for syntax tree.'**
  String get invalidSyntaxTreeRouteData;

  /// No description provided for @noStrongsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Strong\'s'**
  String get noStrongsAvailable;

  /// No description provided for @wordStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Study'**
  String get wordStudyTitle;

  /// No description provided for @seeAllUses.
  ///
  /// In en, this message translates to:
  /// **'See all occurrences'**
  String get seeAllUses;

  /// No description provided for @occurrencesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} occurrences in the Bible'**
  String occurrencesTotal(int count);

  /// No description provided for @showingFirstOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {shown} occurrences'**
  String showingFirstOccurrences(int shown);

  /// No description provided for @wordStudyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Study Unavailable'**
  String get wordStudyUnavailableTitle;

  /// No description provided for @missingWordStudyRouteData.
  ///
  /// In en, this message translates to:
  /// **'No word data was provided for this screen.'**
  String get missingWordStudyRouteData;

  /// No description provided for @syntaxTreeHeuristicNotice.
  ///
  /// In en, this message translates to:
  /// **'Grammatical sketch based on word-order heuristics — not verified syntax data.'**
  String get syntaxTreeHeuristicNotice;

  /// No description provided for @readerMode.
  ///
  /// In en, this message translates to:
  /// **'Reader mode'**
  String get readerMode;

  /// No description provided for @readerModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Gloss rare words inline while you read. Words you have mastered appear plain.'**
  String get readerModeDesc;

  /// No description provided for @vocabularyTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabularyTitle;

  /// No description provided for @dueForReviewSection.
  ///
  /// In en, this message translates to:
  /// **'Due for review'**
  String get dueForReviewSection;

  /// No description provided for @mostFrequentSection.
  ///
  /// In en, this message translates to:
  /// **'Most frequent words'**
  String get mostFrequentSection;

  /// No description provided for @vocabularyCoverage.
  ///
  /// In en, this message translates to:
  /// **'These words cover {percent}% of the text — learn them first.'**
  String vocabularyCoverage(String percent);

  /// No description provided for @hebrewTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Hebrew text'**
  String get hebrewTextTitle;

  /// No description provided for @hebrewTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Reading with fewer marks is a skill milestone'**
  String get hebrewTextDesc;

  /// No description provided for @hebrewTextFull.
  ///
  /// In en, this message translates to:
  /// **'Full (with cantillation)'**
  String get hebrewTextFull;

  /// No description provided for @hebrewTextNoCantillation.
  ///
  /// In en, this message translates to:
  /// **'Vowels only'**
  String get hebrewTextNoCantillation;

  /// No description provided for @hebrewTextConsonantal.
  ///
  /// In en, this message translates to:
  /// **'Consonants only'**
  String get hebrewTextConsonantal;

  /// No description provided for @memorizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorization'**
  String get memorizationTitle;

  /// No description provided for @memorizationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add a psalm and start hiding words.'**
  String get memorizationEmpty;

  /// No description provided for @addPassageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add passage'**
  String get addPassageTitle;

  /// No description provided for @addPassageButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addPassageButton;

  /// No description provided for @selectBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get selectBookLabel;

  /// No description provided for @selectChapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get selectChapterLabel;

  /// No description provided for @masteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery {percent}%'**
  String masteryLabel(String percent);

  /// No description provided for @dueNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get dueNowLabel;

  /// No description provided for @deletePassageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove passage'**
  String get deletePassageTooltip;

  /// No description provided for @levelWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get levelWarmUp;

  /// No description provided for @levelChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get levelChallenge;

  /// No description provided for @levelFirstLetters.
  ///
  /// In en, this message translates to:
  /// **'First letters'**
  String get levelFirstLetters;

  /// No description provided for @tapHiddenWordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a hidden word to reveal it'**
  String get tapHiddenWordHint;

  /// No description provided for @howDidItGo.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get howDidItGo;

  /// No description provided for @struggledButton.
  ///
  /// In en, this message translates to:
  /// **'Struggled'**
  String get struggledButton;

  /// No description provided for @gotItButton.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// No description provided for @nextReviewInDays.
  ///
  /// In en, this message translates to:
  /// **'Saved! Next review in {count} days.'**
  String nextReviewInDays(int count);

  /// No description provided for @nextReviewInHours.
  ///
  /// In en, this message translates to:
  /// **'Saved! Next review in {count} hours.'**
  String nextReviewInHours(int count);

  /// No description provided for @missingMemorizationRouteData.
  ///
  /// In en, this message translates to:
  /// **'No passage data was provided for this screen.'**
  String get missingMemorizationRouteData;

  /// No description provided for @wordResultsSection.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get wordResultsSection;

  /// No description provided for @verseResultsSection.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verseResultsSection;

  /// No description provided for @crossReferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-references'**
  String get crossReferencesTitle;

  /// No description provided for @noCrossReferences.
  ///
  /// In en, this message translates to:
  /// **'No cross-references for this verse.'**
  String get noCrossReferences;

  /// No description provided for @parsingQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Parsing practice'**
  String get parsingQuizTitle;

  /// No description provided for @whatFormIsThis.
  ///
  /// In en, this message translates to:
  /// **'What form is this?'**
  String get whatFormIsThis;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextQuestion;

  /// No description provided for @quizScore.
  ///
  /// In en, this message translates to:
  /// **'You got {score} of {total}'**
  String quizScore(int score, int total);

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get practiceAgain;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @syntaxSourceMacula.
  ///
  /// In en, this message translates to:
  /// **'Syntax trees: MACULA Hebrew & Greek (Clear Bible), CC BY 4.0'**
  String get syntaxSourceMacula;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'What can I read?'**
  String get readabilityTitle;

  /// No description provided for @readabilityAllBooks.
  ///
  /// In en, this message translates to:
  /// **'Every book, most readable first'**
  String get readabilityAllBooks;

  /// No description provided for @readabilityNoText.
  ///
  /// In en, this message translates to:
  /// **'No text is loaded yet.'**
  String get readabilityNoText;

  /// No description provided for @readabilityCanReadNow.
  ///
  /// In en, this message translates to:
  /// **'You can read this now'**
  String get readabilityCanReadNow;

  /// No description provided for @readabilityClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest to readable'**
  String get readabilityClosest;

  /// No description provided for @readabilityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start learning words to see this map fill in'**
  String get readabilityEmptyTitle;

  /// No description provided for @readabilityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'As you master vocabulary, each book shows how much of it you can already read. The most frequent words cover the most text, so progress here is quick at first.'**
  String get readabilityEmptyBody;

  /// No description provided for @openVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Open vocabulary'**
  String get openVocabulary;

  /// No description provided for @reciteAloud.
  ///
  /// In en, this message translates to:
  /// **'Recite aloud'**
  String get reciteAloud;

  /// No description provided for @stopReciting.
  ///
  /// In en, this message translates to:
  /// **'Stop reciting'**
  String get stopReciting;

  /// No description provided for @recitationPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get recitationPreparing;

  /// No description provided for @recitationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recitationStop;

  /// No description provided for @hearItRead.
  ///
  /// In en, this message translates to:
  /// **'Hear it read'**
  String get hearItRead;

  /// No description provided for @phraseSpacingTitle.
  ///
  /// In en, this message translates to:
  /// **'Phrase spacing'**
  String get phraseSpacingTitle;

  /// No description provided for @phraseSpacingDesc.
  ///
  /// In en, this message translates to:
  /// **'Space the Hebrew at the Masoretic accents, so a verse reads in sense units instead of word by word.'**
  String get phraseSpacingDesc;

  /// No description provided for @recitationVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Recitation voice'**
  String get recitationVoiceTitle;

  /// No description provided for @recitationVoiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Read aloud by your device\'s speech voices: Modern Israeli for Hebrew, Modern Greek for Greek. These are living reading traditions, not reconstructed ancient pronunciation.'**
  String get recitationVoiceDesc;

  /// No description provided for @voiceMissing.
  ///
  /// In en, this message translates to:
  /// **'Your device needs a Hebrew or Greek speech voice to read this aloud. Installing one takes a moment and only has to be done once.'**
  String get voiceMissing;

  /// No description provided for @voiceUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device has no speech engine available.'**
  String get voiceUnsupported;

  /// No description provided for @voiceInstall.
  ///
  /// In en, this message translates to:
  /// **'Install voice'**
  String get voiceInstall;

  /// No description provided for @voiceInstallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no voice installer to open.'**
  String get voiceInstallUnavailable;

  /// No description provided for @recitationFailed.
  ///
  /// In en, this message translates to:
  /// **'Recitation could not be started.'**
  String get recitationFailed;

  /// No description provided for @readBook.
  ///
  /// In en, this message translates to:
  /// **'Read {book}'**
  String readBook(String book);

  /// No description provided for @readabilityCoverage.
  ///
  /// In en, this message translates to:
  /// **'You know {percent}% of its vocabulary — about {count} unfamiliar words per chapter.'**
  String readabilityCoverage(int percent, int count);

  /// No description provided for @recitationVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse {number}'**
  String recitationVerse(int number);

  /// No description provided for @voiceMissingFor.
  ///
  /// In en, this message translates to:
  /// **'No {tradition} voice is installed on this device.'**
  String voiceMissingFor(String tradition);

  /// No description provided for @crossReferencesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cross-references'**
  String crossReferencesCount(int count);

  /// No description provided for @onboardingRecitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hear It Recited'**
  String get onboardingRecitationTitle;

  /// No description provided for @onboardingRecitationDesc.
  ///
  /// In en, this message translates to:
  /// **'Press play to hear any chapter read aloud in Hebrew or Greek, by living voices rather than a reconstructed ancient pronunciation. Slow it right down from the speed control until your ear catches up.'**
  String get onboardingRecitationDesc;

  /// No description provided for @readingHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Three ways in'**
  String get readingHintTitle;

  /// No description provided for @readingHintBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a word for its full meaning. Long-press for a quick peek without losing your place. Press ▶ above to hear the chapter recited.'**
  String get readingHintBody;

  /// No description provided for @readingHintDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get readingHintDismiss;

  /// No description provided for @explainTitle.
  ///
  /// In en, this message translates to:
  /// **'Explain this passage'**
  String get explainTitle;

  /// No description provided for @explainLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading the passage…'**
  String get explainLoading;

  /// No description provided for @explainDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Written by AI. It can be wrong — check it against the text.'**
  String get explainDisclaimer;

  /// No description provided for @explainSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI passage explanation'**
  String get explainSettingTitle;

  /// No description provided for @explainSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'Off by default. When on, the passage you are reading is sent over the internet to be explained. Everything else in this app works fully offline.'**
  String get explainSettingDesc;

  /// No description provided for @explainErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. This is the only feature that needs one.'**
  String get explainErrorOffline;

  /// No description provided for @explainErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests just now. Try again in a moment.'**
  String get explainErrorRateLimited;

  /// No description provided for @explainErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The explanation could not be produced.'**
  String get explainErrorGeneric;

  /// No description provided for @explainRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get explainRetry;

  /// No description provided for @explainLowQuality.
  ///
  /// In en, this message translates to:
  /// **'This answer looks off. Try again — and if it keeps happening, the model may need changing.'**
  String get explainLowQuality;

  /// No description provided for @explainFreeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free explanations left today'**
  String explainFreeRemaining(int count);

  /// No description provided for @explainLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free explanations.'**
  String get explainLimitReached;

  /// No description provided for @explainUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited, and a sharper model'**
  String get explainUpgradeTitle;

  /// No description provided for @explainDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI diagnostics'**
  String get explainDiagnosticsTitle;

  /// No description provided for @explainDiagnosticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Success rate and speed of the model answering your questions. Check here if answers seem worse than usual.'**
  String get explainDiagnosticsDesc;

  /// No description provided for @explainNoData.
  ///
  /// In en, this message translates to:
  /// **'No explanations requested yet.'**
  String get explainNoData;

  /// No description provided for @explainClearDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get explainClearDiagnostics;

  /// No description provided for @onboardingAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about any passage'**
  String get onboardingAiTitle;

  /// No description provided for @onboardingAiDesc.
  ///
  /// In en, this message translates to:
  /// **'A tutor trained on your question: what does the Hebrew actually say, what does the Greek carry that English cannot. Tap the ✨ on any verse.'**
  String get onboardingAiDesc;

  /// No description provided for @onboardingAiToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable the AI tutor'**
  String get onboardingAiToggle;

  /// No description provided for @onboardingAiPrivacy.
  ///
  /// In en, this message translates to:
  /// **'This is the only part of the app that uses the internet: the verse you ask about is sent to be explained. Everything else — the text, dictionaries, grammar, audio — works fully offline. You can change this any time in Settings.'**
  String get onboardingAiPrivacy;

  /// Verse menu action: start reading the chapter aloud at this verse instead of the first one.
  ///
  /// In en, this message translates to:
  /// **'Recite from here'**
  String get reciteFromHere;

  /// Heading on the empty search screen.
  ///
  /// In en, this message translates to:
  /// **'Search the Bible'**
  String get searchEmptyTitle;

  /// Explains that search finds verses, with dictionary entries as a secondary result.
  ///
  /// In en, this message translates to:
  /// **'Type any words from a verse to find it. Hebrew and Greek dictionary entries appear underneath the verses.'**
  String get searchEmptyBody;

  /// Title of the beginner's Hebrew and Greek letter reference.
  ///
  /// In en, this message translates to:
  /// **'The alphabet'**
  String get alphabetTitle;

  /// Opening paragraph of the Hebrew alphabet guide.
  ///
  /// In en, this message translates to:
  /// **'Hebrew reads from right to left. There are twenty-two letters and all of them are consonants — the dots and dashes written above and below them are the vowels. Take one letter at a time; there is no hurry.'**
  String get alphabetHebrewIntro;

  /// Opening paragraph of the Greek alphabet guide.
  ///
  /// In en, this message translates to:
  /// **'Greek reads from left to right and has both capital and small letters. Unlike Hebrew, its vowels are letters in their own right. Take one letter at a time; there is no hurry.'**
  String get alphabetGreekIntro;

  /// Section heading above the list of letters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get alphabetLettersSection;

  /// Section heading above the Hebrew vowel points.
  ///
  /// In en, this message translates to:
  /// **'Vowels'**
  String get alphabetVowelsSection;

  /// Explains that Hebrew vowels are marks around a consonant.
  ///
  /// In en, this message translates to:
  /// **'The vowels are marks written around a letter. They are shown here on bet (ב).'**
  String get alphabetVowelsIntro;

  /// Label for a Hebrew letter's word-final shape. Kept lowercase; it sits inline next to the glyph.
  ///
  /// In en, this message translates to:
  /// **'final'**
  String get alphabetFinalForm;

  /// Label above the example biblical word for a letter.
  ///
  /// In en, this message translates to:
  /// **'In the Bible'**
  String get alphabetExampleLabel;

  /// Settings switch: draw connector lines between occurrences of a tapped word.
  ///
  /// In en, this message translates to:
  /// **'Word connections'**
  String get wordConnections;

  /// Explains the word-connection lines and why they are off by default.
  ///
  /// In en, this message translates to:
  /// **'Draw lines between the other occurrences of a word you tap. Off by default, because the lines cross the text you are reading.'**
  String get wordConnectionsDesc;

  /// Subtitle for the memorization entry inside Vocabulary. States the prerequisite plainly: it is for a passage you can already read.
  ///
  /// In en, this message translates to:
  /// **'Hide words in a passage you already read comfortably.'**
  String get memorizationSubtitle;

  /// Onboarding heading for the Christian / Jewish scripture choice.
  ///
  /// In en, this message translates to:
  /// **'Which scriptures are you reading?'**
  String get onboardingTraditionTitle;

  /// Explains that the choice affects ordering and naming only, and is reversible.
  ///
  /// In en, this message translates to:
  /// **'This decides how the books are ordered and what they are called. Nothing is hidden either way, and you can change it in Settings.'**
  String get onboardingTraditionDesc;

  /// Option label: the Protestant canon and ordering.
  ///
  /// In en, this message translates to:
  /// **'Old and New Testament'**
  String get traditionChristian;

  /// Option description for the Christian ordering.
  ///
  /// In en, this message translates to:
  /// **'The Christian order, from Genesis through Revelation.'**
  String get traditionChristianDesc;

  /// Option label: the Tanakh. Transliterate rather than translate this name.
  ///
  /// In en, this message translates to:
  /// **'Tanakh'**
  String get traditionJewish;

  /// Option description for the Tanakh ordering. Keep Torah/Nevi'im/Ketuvim transliterated.
  ///
  /// In en, this message translates to:
  /// **'Torah, Nevi\'im and Ketuvim, in the traditional Jewish order.'**
  String get traditionJewishDesc;

  /// Section heading for the five books of the Torah.
  ///
  /// In en, this message translates to:
  /// **'Torah'**
  String get tanakhTorah;

  /// Section heading for the Prophets. Keep the transliterated name and gloss it.
  ///
  /// In en, this message translates to:
  /// **'Nevi\'im — Prophets'**
  String get tanakhNeviim;

  /// Section heading for the Writings. Keep the transliterated name and gloss it.
  ///
  /// In en, this message translates to:
  /// **'Ketuvim — Writings'**
  String get tanakhKetuvim;

  /// Neutral name for the Hebrew scriptures, used instead of 'Old Testament' for a Jewish reader.
  ///
  /// In en, this message translates to:
  /// **'Hebrew Bible'**
  String get hebrewBibleLabel;

  /// Settings row that opens the scripture-tradition choice.
  ///
  /// In en, this message translates to:
  /// **'Scriptures'**
  String get traditionSettingTitle;

  /// No description provided for @reviewReminderSetting.
  ///
  /// In en, this message translates to:
  /// **'Daily review reminder'**
  String get reviewReminderSetting;

  /// No description provided for @reviewReminderSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An evening nudge when words are due'**
  String get reviewReminderSettingSubtitle;

  /// Notification title when vocabulary is due
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word is ready for review} other{{count} words are ready for review}}'**
  String reminderDueTitle(int count);

  /// No description provided for @reminderDueBody.
  ///
  /// In en, this message translates to:
  /// **'Five minutes now keeps them from slipping away.'**
  String get reminderDueBody;

  /// No description provided for @reminderReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Your verse for today is waiting'**
  String get reminderReadTitle;

  /// No description provided for @reminderReadBody.
  ///
  /// In en, this message translates to:
  /// **'Read one verse in Hebrew or Greek before the day ends.'**
  String get reminderReadBody;

  /// No description provided for @pathTitle.
  ///
  /// In en, this message translates to:
  /// **'Book paths'**
  String get pathTitle;

  /// No description provided for @pathHomeStart.
  ///
  /// In en, this message translates to:
  /// **'Pick a book and learn exactly the words it needs'**
  String get pathHomeStart;

  /// No description provided for @pathChooseBook.
  ///
  /// In en, this message translates to:
  /// **'Choose a book to read in the original'**
  String get pathChooseBook;

  /// No description provided for @pathWordsToGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word to read 80% of it} other{{count} words to read 80% of it}}'**
  String pathWordsToGoal(int count);

  /// No description provided for @pathCoverage.
  ///
  /// In en, this message translates to:
  /// **'You can read {percent}% of {book}'**
  String pathCoverage(int percent, String book);

  /// No description provided for @pathLearning.
  ///
  /// In en, this message translates to:
  /// **'{percent}% counting the words you are learning'**
  String pathLearning(int percent);

  /// No description provided for @pathGoalReached.
  ///
  /// In en, this message translates to:
  /// **'You can read most of this book. Open it and enjoy!'**
  String get pathGoalReached;

  /// No description provided for @pathLearnNext.
  ///
  /// In en, this message translates to:
  /// **'Learn the next words'**
  String get pathLearnNext;

  /// No description provided for @pathWordsInBook.
  ///
  /// In en, this message translates to:
  /// **'Words in this book, most common first'**
  String get pathWordsInBook;

  /// No description provided for @pathChangeBook.
  ///
  /// In en, this message translates to:
  /// **'Change book'**
  String get pathChangeBook;

  /// No description provided for @pathShare.
  ///
  /// In en, this message translates to:
  /// **'Share progress'**
  String get pathShare;

  /// No description provided for @shareCardHebrew.
  ///
  /// In en, this message translates to:
  /// **'I\'ve learned {percent}% of the words in {book}, in Hebrew'**
  String shareCardHebrew(int percent, String book);

  /// No description provided for @shareCardGreek.
  ///
  /// In en, this message translates to:
  /// **'I\'ve learned {percent}% of the words in {book}, in Greek'**
  String shareCardGreek(int percent, String book);

  /// No description provided for @shareCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Learning with Aleph'**
  String get shareCardFooter;

  /// No description provided for @pathAllLearned.
  ///
  /// In en, this message translates to:
  /// **'You have started every word in this book. Keep reviewing!'**
  String get pathAllLearned;

  /// No description provided for @dailySessionStart.
  ///
  /// In en, this message translates to:
  /// **'Today\'s 5 minutes'**
  String get dailySessionStart;

  /// No description provided for @dailySessionDone.
  ///
  /// In en, this message translates to:
  /// **'Done for today. See you tomorrow!'**
  String get dailySessionDone;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String streakDays(int count);

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'What does your name mean?'**
  String get nameTitle;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Type your name'**
  String get nameHint;

  /// No description provided for @nameMeans.
  ///
  /// In en, this message translates to:
  /// **'{name} means “{meaning}”'**
  String nameMeans(String name, String meaning);

  /// No description provided for @nameCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Appears once in the Bible} other{Appears {count} times in the Bible}}'**
  String nameCount(int count);

  /// No description provided for @nameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not on our list yet. Try another spelling.'**
  String get nameNotFound;

  /// No description provided for @nameShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get nameShare;

  /// No description provided for @usageSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage counts'**
  String get usageSharingTitle;

  /// No description provided for @usageSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which features get used. Never what you read, and nothing that identifies you.'**
  String get usageSharingSubtitle;

  /// No description provided for @morphHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get morphHebrew;

  /// No description provided for @morphAramaic.
  ///
  /// In en, this message translates to:
  /// **'Aramaic'**
  String get morphAramaic;

  /// No description provided for @morphAdjective.
  ///
  /// In en, this message translates to:
  /// **'Adjective'**
  String get morphAdjective;

  /// No description provided for @morphConjunction.
  ///
  /// In en, this message translates to:
  /// **'Conjunction'**
  String get morphConjunction;

  /// No description provided for @morphAdverb.
  ///
  /// In en, this message translates to:
  /// **'Adverb'**
  String get morphAdverb;

  /// No description provided for @morphNoun.
  ///
  /// In en, this message translates to:
  /// **'Noun'**
  String get morphNoun;

  /// No description provided for @morphPronoun.
  ///
  /// In en, this message translates to:
  /// **'Pronoun'**
  String get morphPronoun;

  /// No description provided for @morphPreposition.
  ///
  /// In en, this message translates to:
  /// **'Preposition'**
  String get morphPreposition;

  /// No description provided for @morphSuffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get morphSuffix;

  /// No description provided for @morphParticle.
  ///
  /// In en, this message translates to:
  /// **'Particle'**
  String get morphParticle;

  /// No description provided for @morphVerb.
  ///
  /// In en, this message translates to:
  /// **'Verb'**
  String get morphVerb;

  /// No description provided for @morphArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get morphArticle;

  /// No description provided for @morphInterjection.
  ///
  /// In en, this message translates to:
  /// **'Interjection'**
  String get morphInterjection;

  /// No description provided for @morphCommon.
  ///
  /// In en, this message translates to:
  /// **'common'**
  String get morphCommon;

  /// No description provided for @morphProper.
  ///
  /// In en, this message translates to:
  /// **'proper'**
  String get morphProper;

  /// No description provided for @morphGentilic.
  ///
  /// In en, this message translates to:
  /// **'gentilic'**
  String get morphGentilic;

  /// No description provided for @morphMasculine.
  ///
  /// In en, this message translates to:
  /// **'masculine'**
  String get morphMasculine;

  /// No description provided for @morphFeminine.
  ///
  /// In en, this message translates to:
  /// **'feminine'**
  String get morphFeminine;

  /// No description provided for @morphBothGenders.
  ///
  /// In en, this message translates to:
  /// **'both genders'**
  String get morphBothGenders;

  /// No description provided for @morphNeuter.
  ///
  /// In en, this message translates to:
  /// **'neuter'**
  String get morphNeuter;

  /// No description provided for @morphSingular.
  ///
  /// In en, this message translates to:
  /// **'singular'**
  String get morphSingular;

  /// No description provided for @morphPlural.
  ///
  /// In en, this message translates to:
  /// **'plural'**
  String get morphPlural;

  /// No description provided for @morphDual.
  ///
  /// In en, this message translates to:
  /// **'dual'**
  String get morphDual;

  /// No description provided for @morphAbsolute.
  ///
  /// In en, this message translates to:
  /// **'absolute'**
  String get morphAbsolute;

  /// No description provided for @morphConstruct.
  ///
  /// In en, this message translates to:
  /// **'construct'**
  String get morphConstruct;

  /// No description provided for @morphDetermined.
  ///
  /// In en, this message translates to:
  /// **'determined'**
  String get morphDetermined;

  /// No description provided for @morphFirstPerson.
  ///
  /// In en, this message translates to:
  /// **'1st person'**
  String get morphFirstPerson;

  /// No description provided for @morphSecondPerson.
  ///
  /// In en, this message translates to:
  /// **'2nd person'**
  String get morphSecondPerson;

  /// No description provided for @morphThirdPerson.
  ///
  /// In en, this message translates to:
  /// **'3rd person'**
  String get morphThirdPerson;

  /// No description provided for @morphPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get morphPerfect;

  /// No description provided for @morphSequentialPerfect.
  ///
  /// In en, this message translates to:
  /// **'Sequential Perfect'**
  String get morphSequentialPerfect;

  /// No description provided for @morphImperfect.
  ///
  /// In en, this message translates to:
  /// **'Imperfect'**
  String get morphImperfect;

  /// No description provided for @morphSequentialImperfect.
  ///
  /// In en, this message translates to:
  /// **'Sequential Imperfect'**
  String get morphSequentialImperfect;

  /// No description provided for @morphCohortative.
  ///
  /// In en, this message translates to:
  /// **'Cohortative'**
  String get morphCohortative;

  /// No description provided for @morphJussive.
  ///
  /// In en, this message translates to:
  /// **'Jussive'**
  String get morphJussive;

  /// No description provided for @morphImperative.
  ///
  /// In en, this message translates to:
  /// **'Imperative'**
  String get morphImperative;

  /// No description provided for @morphParticipleActive.
  ///
  /// In en, this message translates to:
  /// **'Participle Active'**
  String get morphParticipleActive;

  /// No description provided for @morphParticiplePassive.
  ///
  /// In en, this message translates to:
  /// **'Participle Passive'**
  String get morphParticiplePassive;

  /// No description provided for @morphInfinitiveAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Infinitive Absolute'**
  String get morphInfinitiveAbsolute;

  /// No description provided for @morphInfinitiveConstruct.
  ///
  /// In en, this message translates to:
  /// **'Infinitive Construct'**
  String get morphInfinitiveConstruct;

  /// No description provided for @morphCardinalNumber.
  ///
  /// In en, this message translates to:
  /// **'cardinal number'**
  String get morphCardinalNumber;

  /// No description provided for @morphOrdinalNumber.
  ///
  /// In en, this message translates to:
  /// **'ordinal number'**
  String get morphOrdinalNumber;

  /// No description provided for @morphDemonstrative.
  ///
  /// In en, this message translates to:
  /// **'demonstrative'**
  String get morphDemonstrative;

  /// No description provided for @morphIndefinite.
  ///
  /// In en, this message translates to:
  /// **'indefinite'**
  String get morphIndefinite;

  /// No description provided for @morphInterrogative.
  ///
  /// In en, this message translates to:
  /// **'interrogative'**
  String get morphInterrogative;

  /// No description provided for @morphPersonal.
  ///
  /// In en, this message translates to:
  /// **'personal'**
  String get morphPersonal;

  /// No description provided for @morphRelative.
  ///
  /// In en, this message translates to:
  /// **'relative'**
  String get morphRelative;

  /// No description provided for @morphReciprocal.
  ///
  /// In en, this message translates to:
  /// **'reciprocal'**
  String get morphReciprocal;

  /// No description provided for @morphReflexive.
  ///
  /// In en, this message translates to:
  /// **'reflexive'**
  String get morphReflexive;

  /// No description provided for @morphPossessive.
  ///
  /// In en, this message translates to:
  /// **'possessive'**
  String get morphPossessive;

  /// No description provided for @morphCorrelative.
  ///
  /// In en, this message translates to:
  /// **'correlative'**
  String get morphCorrelative;

  /// No description provided for @morphDirectional.
  ///
  /// In en, this message translates to:
  /// **'directional'**
  String get morphDirectional;

  /// No description provided for @morphParagogicHe.
  ///
  /// In en, this message translates to:
  /// **'paragogic he'**
  String get morphParagogicHe;

  /// No description provided for @morphParagogicNun.
  ///
  /// In en, this message translates to:
  /// **'paragogic nun'**
  String get morphParagogicNun;

  /// No description provided for @morphPronominal.
  ///
  /// In en, this message translates to:
  /// **'pronominal'**
  String get morphPronominal;

  /// No description provided for @morphPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get morphPresent;

  /// No description provided for @morphFuture.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get morphFuture;

  /// No description provided for @morphAorist.
  ///
  /// In en, this message translates to:
  /// **'Aorist'**
  String get morphAorist;

  /// No description provided for @morphPluperfect.
  ///
  /// In en, this message translates to:
  /// **'Pluperfect'**
  String get morphPluperfect;

  /// No description provided for @morphNoTense.
  ///
  /// In en, this message translates to:
  /// **'No tense'**
  String get morphNoTense;

  /// No description provided for @morphActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get morphActive;

  /// No description provided for @morphMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get morphMiddle;

  /// No description provided for @morphPassive.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get morphPassive;

  /// No description provided for @morphMiddlePassive.
  ///
  /// In en, this message translates to:
  /// **'Middle/Passive'**
  String get morphMiddlePassive;

  /// No description provided for @morphMiddleDeponent.
  ///
  /// In en, this message translates to:
  /// **'Middle Deponent'**
  String get morphMiddleDeponent;

  /// No description provided for @morphPassiveDeponent.
  ///
  /// In en, this message translates to:
  /// **'Passive Deponent'**
  String get morphPassiveDeponent;

  /// No description provided for @morphMiddlePassiveDeponent.
  ///
  /// In en, this message translates to:
  /// **'Middle/Passive Deponent'**
  String get morphMiddlePassiveDeponent;

  /// No description provided for @morphIndicative.
  ///
  /// In en, this message translates to:
  /// **'Indicative'**
  String get morphIndicative;

  /// No description provided for @morphSubjunctive.
  ///
  /// In en, this message translates to:
  /// **'Subjunctive'**
  String get morphSubjunctive;

  /// No description provided for @morphOptative.
  ///
  /// In en, this message translates to:
  /// **'Optative'**
  String get morphOptative;

  /// No description provided for @morphInfinitive.
  ///
  /// In en, this message translates to:
  /// **'Infinitive'**
  String get morphInfinitive;

  /// No description provided for @morphParticiple.
  ///
  /// In en, this message translates to:
  /// **'Participle'**
  String get morphParticiple;

  /// No description provided for @morphNominative.
  ///
  /// In en, this message translates to:
  /// **'Nominative'**
  String get morphNominative;

  /// No description provided for @morphGenitive.
  ///
  /// In en, this message translates to:
  /// **'Genitive'**
  String get morphGenitive;

  /// No description provided for @morphDative.
  ///
  /// In en, this message translates to:
  /// **'Dative'**
  String get morphDative;

  /// No description provided for @morphAccusative.
  ///
  /// In en, this message translates to:
  /// **'Accusative'**
  String get morphAccusative;

  /// No description provided for @morphVocative.
  ///
  /// In en, this message translates to:
  /// **'Vocative'**
  String get morphVocative;

  /// No description provided for @contentSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Shown in English; no translation is available yet.'**
  String get contentSourceNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
