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
  /// **'Original Bible'**
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
  /// **'Tap on any word to see its definition, pronunciation, and grammatical information. Toggle the pronunciation button to see how words are spoken.'**
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

  /// No description provided for @learningModeEnglishOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Learning Mode currently supports English translations only.'**
  String get learningModeEnglishOnlyNotice;

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
